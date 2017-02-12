include Economic
class Invoice < ActiveRecord::Base
  belongs_to :user
  has_many :shipments
  has_many :rows, :class_name => 'InvoiceRow', :dependent => :destroy
  
  def pretty_id
    if economic_id
      economic_id
    else
      "TMP_#{id}"
    end
  end
  
  def customer
    user
  end
  
  def can_capture_online
    not captured_online and user.can_pay_online and sent_to_economic
  end
  
  
  def self.identify_economic_ids
    Invoice.where('economic_id IS NULL').each do |invoice|
      Economic.identify_booked_invoice invoice
    end
  end
  
  def self.fetch_economic_data
    Invoice.where('economic_id IS NOT NULL AND 1=1').each do |invoice|
      Economic.get_invoice_data invoice
    end
  end
end
