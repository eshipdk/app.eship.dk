class AddIsInterlineToImportFormats < ActiveRecord::Migration
  def change
    add_column :import_formats, :is_interline, :boolean
  end
end
