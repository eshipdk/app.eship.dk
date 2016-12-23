class AddCapturedOnlineToInvoices < ActiveRecord::Migration
  def change
    add_column :invoices, :captured_online, :boolean, default: false
  end
end
