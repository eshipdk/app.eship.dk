class AddRemarksToShipments < ActiveRecord::Migration
  def change
    add_column :shipments, :remarks, :string
  end
end
