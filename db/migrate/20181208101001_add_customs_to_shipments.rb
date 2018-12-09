class AddCustomsToShipments < ActiveRecord::Migration
  def change
    add_column :shipments, :customs_amount, :decimal
    add_column :shipments, :customs_currency, :string
    add_column :shipments, :customs_code, :string
  end
end
