class AddDefaultCountryToUserProducts < ActiveRecord::Migration
  def change
    add_column :user_products, :default_country, :string
  end
end
