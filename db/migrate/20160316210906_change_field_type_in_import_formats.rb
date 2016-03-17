class ChangeFieldTypeInImportFormats < ActiveRecord::Migration
  def change
    change_column :import_formats, :return, :string
    change_column :import_formats, :product_code, :string
    change_column :import_formats, :package_height, :string
    change_column :import_formats, :package_length, :string
    change_column :import_formats, :package_width, :string
    change_column :import_formats, :package_weight, :string
    change_column :import_formats, :sender_company_name, :string
    change_column :import_formats, :sender_attention, :string
    change_column :import_formats, :sender_address_line1, :string
    change_column :import_formats, :sender_address_line2, :string
    change_column :import_formats, :sender_zip_code, :string
    change_column :import_formats, :sender_city, :string
    change_column :import_formats, :sender_country_code, :string
    change_column :import_formats, :sender_phone_number, :string
    change_column :import_formats, :sender_email, :string
    change_column :import_formats, :recipient_company_name, :string
    change_column :import_formats, :recipient_attention, :string
    change_column :import_formats, :recipient_address_line1, :string
    change_column :import_formats, :recipient_address_line2, :string
    change_column :import_formats, :recipient_zip_code, :string
    change_column :import_formats, :recipient_city, :string
    change_column :import_formats, :recipient_country_code, :string
    change_column :import_formats, :recipient_phone_number, :string
    change_column :import_formats, :recipient_email, :string
    change_column :import_formats, :description, :string
    change_column :import_formats, :amount, :string
    change_column :import_formats, :reference, :string
    change_column :import_formats, :parcelshop_id, :string
  end
end
