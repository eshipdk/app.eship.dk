class AddCostToInvoices < ActiveRecord::Migration
  def change
    add_column :invoices, :cost, :decimal,
               :precision => 16, :scale => 2
    add_column :invoice_rows, :cost, :decimal,
               :precision => 16, :scale => 2
  end
end
