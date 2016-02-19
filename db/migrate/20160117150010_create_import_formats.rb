class CreateImportFormats < ActiveRecord::Migration
  def change
    create_table :import_formats do |t|
      t.references :user, index: true, foreign_key: true
      t.integer :return
      t.integer :product_code
      t.integer :package_height
      t.integer :package_length
      t.integer :package_width
      t.integer :package_weight
      t.integer :sender_company_name
      t.integer :sender_attention
      t.integer :sender_address_line1
      t.integer :sender_address_line2
      t.integer :sender_zip_code
      t.integer :sender_city
      t.integer :sender_country_code
      t.integer :sender_phone_number
      t.integer :sender_email
      t.integer :recipient_company_name
      t.integer :recipient_attention
      t.integer :recipient_address_line1
      t.integer :recipient_address_line2
      t.integer :recipient_zip_code
      t.integer :recipient_city
      t.integer :recipient_country_code
      t.integer :recipient_phone_number
      t.integer :recipient_email

      t.timestamps null: false
    end
  end
end
