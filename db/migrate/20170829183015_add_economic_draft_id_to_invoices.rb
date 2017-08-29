class AddEconomicDraftIdToInvoices < ActiveRecord::Migration
  def change
    add_column :invoices, :economic_draft_id, :integer
  end
end
