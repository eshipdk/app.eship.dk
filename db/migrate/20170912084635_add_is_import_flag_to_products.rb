class AddIsImportFlagToProducts < ActiveRecord::Migration
  def change
    add_column :products, :is_import, :boolean, default: false
  end
end
