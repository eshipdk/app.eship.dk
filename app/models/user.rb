class User < ActiveRecord::Base
  attr_accessor :password
  EMAIL_REGEX = /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i
  validates :email, :presence => true, :uniqueness => true, :format => EMAIL_REGEX
  validates :password, :confirmation => true #password_confirmation attr
  validates_length_of :password, :in => 6..20, :on => :create
  validates_length_of :password, :in => 6..20, :on => :update, :allow_blank => true
  enum role: [:admin, :customer]

  has_many :products, :through => :user_products
  has_many :user_products, :dependent => :destroy
  has_many :addresses, :through => :address_book_records
  has_many :address_book_records, :dependent => :destroy
  has_many :shipments, :dependent => :destroy
  has_one :import_format, :dependent => :destroy
  belongs_to :default_address, :class_name => 'Address' , :foreign_key => 'address_id'

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

  def add_product(product)
    self.user_products.build(:product => product)
  end

  def holds_product(product)
   for p in products
     if p.id == product.id
       return true
     end
   end
    return false
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

