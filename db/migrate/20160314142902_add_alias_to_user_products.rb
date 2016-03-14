class AddAliasToUserProducts < ActiveRecord::Migration
  def change
    add_column :user_products, :alias, :string
  end
end
