class AddPrintedTsToShipments < ActiveRecord::Migration
  def change
    add_column :shipments, :label_printed_at, :datetime
  end
end
