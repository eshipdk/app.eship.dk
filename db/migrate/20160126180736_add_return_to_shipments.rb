class AddReturnToShipments < ActiveRecord::Migration
  def change
    add_column :shipments, :return, :boolean
  end
end
