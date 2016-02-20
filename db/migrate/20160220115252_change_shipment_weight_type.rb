class ChangeShipmentWeightType < ActiveRecord::Migration
  def change
    change_column :shipments, :package_weight, :float
  end
end
