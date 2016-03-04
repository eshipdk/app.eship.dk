class AddCallbackUrlToShipments < ActiveRecord::Migration
  def change
    add_column :shipments, :callback_url, :string
  end
end
