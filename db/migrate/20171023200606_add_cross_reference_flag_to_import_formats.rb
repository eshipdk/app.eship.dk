class AddCrossReferenceFlagToImportFormats < ActiveRecord::Migration
  def change
    add_column :import_formats, :cross_reference_flag, :boolean, default: false
  end
end
