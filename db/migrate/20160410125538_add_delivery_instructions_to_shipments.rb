class AddDeliveryInstructionsToShipments < ActiveRecord::Migration
  def change
    add_column :shipments, :delivery_instructions, :string
  end
end
