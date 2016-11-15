class AddEconomicFieldsToInvoiceRows < ActiveRecord::Migration
  def change
    add_column :invoice_rows, :product_code, :string, :default => "unknown"
    add_column :invoice_rows, :qty, :int, :default => 1
    add_column :invoice_rows, :unit_price, :decimal, :precision => 30, :scale => 2, :default => 0
  end
end
