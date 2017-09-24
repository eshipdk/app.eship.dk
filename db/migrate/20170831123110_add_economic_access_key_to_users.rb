class AddEconomicAccessKeyToUsers < ActiveRecord::Migration
  def change
    add_column :users, :economic_api_key, :string
  end
end
