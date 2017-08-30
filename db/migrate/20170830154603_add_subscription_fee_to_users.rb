class AddSubscriptionFeeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :subscription_fee, :integer, default: 0
  end
end
