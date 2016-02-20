class AddDescriptionToImportFormat < ActiveRecord::Migration
  def change
    add_column :import_formats, :description, :integer
  end
end
