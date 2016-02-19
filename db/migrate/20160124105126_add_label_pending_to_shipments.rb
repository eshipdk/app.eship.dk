class AddLabelPendingToShipments < ActiveRecord::Migration
  def change
    add_column :shipments, :label_pending, :boolean
  end
end
