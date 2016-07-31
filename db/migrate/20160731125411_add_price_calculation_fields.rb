class AddPriceCalculationFields < ActiveRecord::Migration
  def change
    add_column :shipments, :final_price, :decimal, :precision => 30, :scale => 2
    add_column :shipments, :diesel_fee, :decimal, :precision => 30, :scale => 2
    add_column :shipments, :final_diesel_fee, :decimal, :precision => 30, :scale => 2
    add_column :shipments, :value_determined, :boolean
  end
end
