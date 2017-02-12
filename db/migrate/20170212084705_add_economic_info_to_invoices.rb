class AddEconomicInfoToInvoices < ActiveRecord::Migration
  def change
    add_column :invoices, :economic_id, :integer
  end
end
