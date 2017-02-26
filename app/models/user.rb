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
  enum billing_control: [:manual, :by_time, :by_balance]
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
  belongs_to :affiliate_user, :class_name => 'User', :foreign_key => 'affiliate_id'
  belongs_to :default_address, :class_name => 'Address' , :foreign_key => 'address_id'
  belongs_to :contact_address, :class_name => 'Address', :foreign_key => 'contact_address_id'

  before_create :create_unique_api_key
  before_save :encrypt_password
  after_save :clear_password



  def self.authenticate(email="", login_password="")
    user = User.find_by_email(email)
    if user && user.match_password(login_password)
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
    return user
  end

  def roles
    [["Admin", :admin], ["Customer", :customer], ['Affiliate', :affiliate]]
  end
  
  def self.role_options
    {'Admin' => :admin, 'Customer' => :customer, 'Affiliate' => :affiliate}
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
    calc_value uninvoiced_shipments
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
  
  def do_invoice
    shipments = uninvoiced_shipments
    n = shipments.count
    if n < 1
      raise 'No shipments to invoice.'
    end
    invoice = Invoice.new()
    invoice.user = self
    invoice.n_shipments = n

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
          qty += 1
        end
        row.qty = qty
        row.unit_price = row.amount / row.qty
        row.product_code = 'label_fee'
        group_rows[product_code] = [row]
      end
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
    return invoice
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
    
    Rails.logger.warn "#{Time.now.utc.iso8601} TASK ENDED: User.perform_automatic_invoicing"
  end
  
  
  def verify_epay_subscription
    if epay? and epay_subscription_id == nil
      return false
    else
      return true
    end
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
  

  
  
end
