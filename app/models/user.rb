class User < ActiveRecord::Base
  attr_accessor :password
  EMAIL_REGEX = /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i
  validates :email, :presence => true, :uniqueness => true, :format => EMAIL_REGEX
  validates :password, :confirmation => true #password_confirmation attr
  validates_length_of :password, :in => 6..20, :on => :create
  validates_length_of :password, :in => 6..20, :on => :update, :if => :password
  enum role: [:admin, :customer]
  enum billing_type: [:free, :flat_price, :advanced] #flat_price: Pays a flat fee per label ordered. advanced: use pricing schemes per product

  has_many :products, :through => :user_products
  has_many :user_products, :dependent => :destroy
  has_many :addresses, :through => :address_book_records
  has_many :address_book_records, :dependent => :destroy
  has_many :shipments, :dependent => :destroy
  has_many :invoices, :dependent => :destroy
  has_many :pricing_schemes, :dependent => :destroy
  has_one :import_format, :dependent => :destroy
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
    [["Admin", :admin], ["Customer", :customer]]
  end
  
  def self.role_options
    {'Admin' => :admin, 'Customer' => :customer}
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

  def billing_type_title
    return User.billing_type_title billing_type
  end
  
  
  def balance
    calc_value uninvoiced_shipments
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
    shipments.filter_uninvoiced
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
   
   product_groups = {}
   shipments.each do |shipment|
     product_code = shipment.product.product_code
     if not product_groups.key?(product_code)
       product_groups[product_code] = {'shipments' => [shipment], 'product' => shipment.product}
     else
       product_groups[product_code]['shipments'].push(shipment)
     end
   end
   
   group_rows = {}
   product_groups.each do |product_code, group|
     product = group['product']
     group_shipments = group['shipments']
     group_rows[product_code] = (product.price_scheme self).generate_invoice_rows group_shipments
   end
   
   invoice.save
   amount = 0
   group_rows.each do |product_code, rows|
     
     rows.each do |row|
       row.invoice = invoice
       row.save
       amount += row.amount
     end
   end
   invoice.amount = amount
   invoice.save
   
   shipments.each do |shipment|
    shipment.invoiced = true
    shipment.invoice = invoice
    shipment.save  
   end
   
 end
 
#  def do_invoice
#    shipments = uninvoiced_shipments
#    n = shipments.count
#    if n < 1
#      raise 'No shipments to invoice.'
#    end
#    value, issues = calc_value shipments
#    if issues
#      raise 'Invoice cancelled -> Issues occured while calculating prices: ' + issues.to_s
#    end
#    
#    invoice = Invoice.new()
#    invoice.amount = value
#    invoice.user = self
#    invoice.n_shipments = n
#    invoice.save()
#    
#    for shipment in shipments do
#      shipment.invoiced = true
#      shipment.invoice = invoice
#      shipment.save()
#    end
#  end
  
  
  def total_shipments_invoiced
    invoices.sum(:n_shipments)
  end
  
  def total_amount_invoiced
    invoices.sum(:amount)
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
  
  
  def quick_select_addresses key
    addresses.joins(:address_book_record).where('address_book_records.quick_select_' + key => true) 
  end

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

