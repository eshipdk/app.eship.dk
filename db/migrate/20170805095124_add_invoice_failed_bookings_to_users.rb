class AddInvoiceFailedBookingsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :invoice_failed_bookings, :boolean, default: false
  end
end
