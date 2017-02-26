class AddPaidToInvoices < ActiveRecord::Migration
  def change
    add_column :invoices, :paid, :boolean, null: false, default: false
  end
end
