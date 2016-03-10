class CreateInvoices < ActiveRecord::Migration
  def change
    create_table :invoices do |t|
      t.references :user, index: true, foreign_key: true
      t.column :amount, :decimal, :precision => 16, :scale => 2
      t.timestamps null: false
    end
  end
end
