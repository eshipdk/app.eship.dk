class AddNShipmentsToInvoices < ActiveRecord::Migration
  def change
    add_column :invoices, :n_shipments, :integer
  end
end
