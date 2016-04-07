class AddRemarksToImportFormats < ActiveRecord::Migration
  def change
    add_column :import_formats, :remarks, :string, :default => '{{}}'
  end
end
