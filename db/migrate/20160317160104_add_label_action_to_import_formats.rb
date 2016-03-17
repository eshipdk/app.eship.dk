class AddLabelActionToImportFormats < ActiveRecord::Migration
  def change
    add_column :import_formats, :label_action, :string, :default => '{{print}}'
  end
end
