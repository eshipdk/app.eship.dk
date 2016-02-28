class RemoveInterlinev1FromImportFormats < ActiveRecord::Migration
  def change
    remove_column :import_formats, :is_interline
  end
end
