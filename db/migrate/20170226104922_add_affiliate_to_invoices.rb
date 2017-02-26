class AddAffiliateToInvoices < ActiveRecord::Migration
  def up
    change_table :invoices do |t|
      t.references :affiliate, references: :users
    end
  end
  def down
    remove_column :invoices, :affiliate_id
  end
end
