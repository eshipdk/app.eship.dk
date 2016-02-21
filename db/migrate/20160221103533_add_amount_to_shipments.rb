class AddAmountToShipments < ActiveRecord::Migration
  def change
    add_column :shipments, :amount, :integer, default: 1
  end
end
