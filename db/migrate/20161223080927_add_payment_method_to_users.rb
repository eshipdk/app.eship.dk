class AddPaymentMethodToUsers < ActiveRecord::Migration
  def change
    add_column :users, :payment_method, :integer, default: 0
    add_column :users, :epay_subscription_id, :string
  end
end
