class AddDeliveryInstructionsToImportFormats < ActiveRecord::Migration
  def change
    add_column :import_formats, :delivery_instructions, :string, :default => '{{}}'
  end
end
