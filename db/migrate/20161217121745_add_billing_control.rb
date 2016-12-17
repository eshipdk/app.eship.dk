class AddBillingControl < ActiveRecord::Migration
  def change
    add_column :users, :billing_control, :integer, default: 0
    add_column :users, :invoice_x_days, :integer, default: 7
    add_column :users, :invoice_x_balance, :integer, default: 500  
  end
end
