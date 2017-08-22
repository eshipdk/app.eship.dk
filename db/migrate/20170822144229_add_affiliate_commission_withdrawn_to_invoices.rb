class AddAffiliateCommissionWithdrawnToInvoices < ActiveRecord::Migration
  def change
    add_column :invoices, :affiliate_commission_withdrawn, :boolean, default: false
  end
end
