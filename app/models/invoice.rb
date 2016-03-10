class Invoice < ActiveRecord::Base
  belongs_to :user
  has_many :shipments
end
