class AddReturnProductToProducts < ActiveRecord::Migration
  def up
    change_table :products do |t|
      t.references :return_product, references: :products
    end
  end
  def down
    remove_column :products, :return_product_id
  end
end
