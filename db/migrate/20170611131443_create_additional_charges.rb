class CreateAdditionalCharges < ActiveRecord::Migration
  def change
    create_table :additional_charges do |t|
      t.references :user, index: true, foreign_key: true
      t.references :invoice, index: true, foreign_key: true
      t.references :shipment, index: true, foreign_key: true
      t.column :cost, :decimal, :precision => 16, :scale => 2
      t.column :price, :decimal, :precision => 16, :scale => 2
      t.string :product_code
      t.string :description
    end
  end
end
