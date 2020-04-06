class AddOriginalCodeToProducts < ActiveRecord::Migration
  def change
    add_column :products, :original_code, :string, :unique => true
  end
end
