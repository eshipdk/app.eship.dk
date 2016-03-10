class AddBillingTypeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :billing_type, :integer, :default => 0
  end
end
