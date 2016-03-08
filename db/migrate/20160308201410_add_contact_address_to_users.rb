class AddContactAddressToUsers < ActiveRecord::Migration
  def change
    add_column :users, :contact_address_id, :integer, references: :addresses
  end
end
