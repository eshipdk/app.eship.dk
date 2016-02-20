class AddShipmentDescription < ActiveRecord::Migration
  def change
    add_column :shipments, :description, :string
  end
end
