class AddDelimiterToImportFormats < ActiveRecord::Migration
  def change
    add_column :import_formats, :delimiter, 'char(1)', :default => ';'
  end
end
