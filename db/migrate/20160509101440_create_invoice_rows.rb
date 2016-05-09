class CreateInvoiceRows < ActiveRecord::Migration
  def change
    create_table :invoice_rows do |t|
      t.references :invoice, index: true, foreign_key: true
      t.column :amount, :decimal, :precision => 16, :scale => 2
      t.string :description
    end
  end
end
