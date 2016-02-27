class AddParcelshopIdToImportFormats < ActiveRecord::Migration
  def change
    add_column :import_formats, :parcelshop_id, :integer
  end
end
