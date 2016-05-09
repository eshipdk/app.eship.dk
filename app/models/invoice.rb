class Invoice < ActiveRecord::Base
  belongs_to :user
  has_many :shipments
  has_many :rows, :class_name => 'InvoiceRow', :dependent => :destroy
end
