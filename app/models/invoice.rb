class Invoice < ActiveRecord::Base
  belongs_to :user
  has_many :shipments
  has_many :rows, :class_name => 'InvoiceRow', :dependent => :destroy
  
  def customer
    user
  end
  
  def can_capture_online
    not captured_online and user.can_pay_online and sent_to_economic
  end
end
