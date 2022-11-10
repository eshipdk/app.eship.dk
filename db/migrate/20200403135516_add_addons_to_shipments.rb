class AddAddonsToShipments < ActiveRecord::Migration
  def change
    add_column :shipments, :addons, :string
  end
end
