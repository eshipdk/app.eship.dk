class AddLabelActionToShipments < ActiveRecord::Migration
  def change
    add_column :shipments, :label_action, :integer, :default => 0
  end
end
