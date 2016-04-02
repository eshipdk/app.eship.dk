class AddQuickSelectFieldsToAddressBookRecords < ActiveRecord::Migration
  def change
    add_column :address_book_records, :quick_select_sender, :boolean, :default => false
    add_column :address_book_records, :quick_select_recipient, :boolean, :default => false
  end
end
