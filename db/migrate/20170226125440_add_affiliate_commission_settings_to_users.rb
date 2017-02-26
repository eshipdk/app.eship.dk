class AddAffiliateCommissionSettingsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :affiliate_commission_rate, :decimal,
               :precision => 16, :scale => 2, :default => 0.5
    add_column :users, :affiliate_base_house_amount, :decimal,
               :precision => 16, :scale => 2, :default => 2
    add_column :users, :affiliate_minimum_invoice_amount, :decimal,
               :precision => 16, :scale => 2, :default => 500
  end
end
