class AddImportShipmentsFromCfToUsers < ActiveRecord::Migration
  def change
    add_column :users, :import_shipments_from_cf, :boolean, default: false
  end
end
