class AddCommissionsToInvoices < ActiveRecord::Migration
  def change
    add_column :invoices, :profit, :decimal,
               :precision => 16, :scale => 2
    add_column :invoices, :affiliate_commission, :decimal,
               :precision => 16, :scale => 2
    add_column :invoices, :house_commission, :decimal,
               :precision => 16, :scale => 2
  end
end
