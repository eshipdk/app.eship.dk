class CreateAddresses < ActiveRecord::Migration
  def change
    create_table :addresses do |t|
      t.string :company_name
      t.string :attention
      t.string :address_line1
      t.string :address_line2
      t.column :zip_code, :integer
      t.string :city
      t.string :country_code
      t.string :phone_number
      t.string :email

      t.timestamps null: false
    end
  end
end
