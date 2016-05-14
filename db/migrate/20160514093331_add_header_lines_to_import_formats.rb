class AddHeaderLinesToImportFormats < ActiveRecord::Migration
  def change
    add_column :import_formats, :header_lines, :integer, :default => 0
  end
end
