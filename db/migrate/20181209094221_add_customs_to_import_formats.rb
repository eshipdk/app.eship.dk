class AddCustomsToImportFormats < ActiveRecord::Migration
  def change
    add_column :import_formats, :customs_amount, :string, :default => "{{}}"
    add_column :import_formats, :customs_currency, :string, :default => "{{}}"
    add_column :import_formats, :customs_code, :string, :default => "{{}}"
  end
end
