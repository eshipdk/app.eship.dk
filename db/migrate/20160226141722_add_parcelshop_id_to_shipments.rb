class AddParcelshopIdToShipments < ActiveRecord::Migration
  def change
    add_column :shipments, :parcelshop_id, :string
  end
end
