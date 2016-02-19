class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :product_code

      t.timestamps null: false
    end
  end
end
