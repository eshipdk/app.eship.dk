class AddressBookRecord < ActiveRecord::Base
  belongs_to :user
  belongs_to :address, :dependent => :destroy
end
