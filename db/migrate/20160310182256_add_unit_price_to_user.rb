class AddUnitPriceToUser < ActiveRecord::Migration
  def change
    add_column :users, :unit_price, :decimal, :precision => 16, :scale => 2, default: 0
  end
end
