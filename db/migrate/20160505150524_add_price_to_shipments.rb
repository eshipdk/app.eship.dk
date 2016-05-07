class AddPriceToShipments < ActiveRecord::Migration
  def change
    add_column :shipments, :price, :decimal, :precision => 30, :scale => 2
    add_column :shipments, :cost, :decimal, :precision => 30, :scale => 2
  end
end
