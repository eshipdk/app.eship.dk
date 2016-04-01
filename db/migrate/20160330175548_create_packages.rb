class CreatePackages < ActiveRecord::Migration
  
  def up
    create_table :packages do |t|
      t.float :width
      t.float :height
      t.float :length
      t.float :weight
      t.integer :amount, default: 1
      t.references :shipment, index: true, foreign_key: true

      t.timestamps null: false
    end
    
    Shipment.all.each do |shipment|
      package = Package.new
      package.width = shipment.package_width
      package.height = shipment.package_height
      package.length = shipment.package_length
      package.weight = shipment.package_weight
      package.shipment = shipment
      package.save
    end
  end
  
  def down
    drop_table :packages
  end
end
