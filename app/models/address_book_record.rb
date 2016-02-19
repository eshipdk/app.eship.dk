class AddressBookRecord < ActiveRecord::Base
  belongs_to :user
  belongs_to :address
end
