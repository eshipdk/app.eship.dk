class AddAmountToImportFormats < ActiveRecord::Migration
  def change
    add_column :import_formats, :amount, :integer
  end
end
