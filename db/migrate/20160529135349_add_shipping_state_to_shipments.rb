class AddShippingStateToShipments < ActiveRecord::Migration
  def change
    add_column :shipments, :shipping_state, :integer, default: 0
  end
end
