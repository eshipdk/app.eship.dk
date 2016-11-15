class AddEconomicCustomerIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :economic_customer_id, :int
  end
end
