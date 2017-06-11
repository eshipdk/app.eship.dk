class AdditionalCharge < ActiveRecord::Base
  belongs_to :shipment
  belongs_to :user
  belongs_to :invoice
end