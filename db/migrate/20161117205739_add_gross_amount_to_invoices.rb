class AddGrossAmountToInvoices < ActiveRecord::Migration
  def change
    add_column :invoices, :gross_amount, :decimal, :precision => 16, :scale => 2, :default => 0
  end
end
