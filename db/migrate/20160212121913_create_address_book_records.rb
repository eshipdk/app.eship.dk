class CreateAddressBookRecords < ActiveRecord::Migration
  def change
    create_table :address_book_records do |t|
      t.references :user, index: true, foreign_key: true
      t.references :address, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
