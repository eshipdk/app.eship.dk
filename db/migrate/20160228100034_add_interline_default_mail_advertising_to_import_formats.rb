class AddInterlineDefaultMailAdvertisingToImportFormats < ActiveRecord::Migration
  def change
    add_column :import_formats, :interline_default_mail_advertising, :boolean
  end
end
