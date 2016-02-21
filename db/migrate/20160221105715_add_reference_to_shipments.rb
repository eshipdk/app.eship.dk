class AddReferenceToShipments < ActiveRecord::Migration
  def change
    add_column :shipments, :reference, :string
    add_column :import_formats, :reference, :integer
  end
end
