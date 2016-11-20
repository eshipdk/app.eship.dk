class AddTaxedToProducts < ActiveRecord::Migration
  def change
    add_column :products, :taxed, :bool, :default => true
  end
end
