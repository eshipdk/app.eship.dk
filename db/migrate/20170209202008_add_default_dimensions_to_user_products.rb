class AddDefaultDimensionsToUserProducts < ActiveRecord::Migration
  def change
    add_column :user_products, :default_length, :float
    add_column :user_products, :default_width, :float
    add_column :user_products, :default_height, :float
    add_column :user_products, :default_weight, :float
  end
end
