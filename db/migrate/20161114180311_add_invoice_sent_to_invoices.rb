class AddInvoiceSentToInvoices < ActiveRecord::Migration
  def change
    add_column :invoices, :sent_to_economic, :bool, :default => false
  end
end
