class AddImporterToImportFormats < ActiveRecord::Migration
  def change
     add_column :import_formats, :importer, :integer, default: 0
  end
end
