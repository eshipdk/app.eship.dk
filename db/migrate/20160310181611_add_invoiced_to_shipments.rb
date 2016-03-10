class AddInvoicedToShipments < ActiveRecord::Migration
  def change
    add_column :shipments, :invoiced, :boolean, default: false
  end
end
