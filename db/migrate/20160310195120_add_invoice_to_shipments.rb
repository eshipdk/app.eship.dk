class AddInvoiceToShipments < ActiveRecord::Migration
  def change
    add_reference :shipments, :invoice, index: true, foreign_key: true
  end
end
