class AddDisabledToProducts < ActiveRecord::Migration
  def change
    add_column :products, :disabled, :boolean, default: false
  end
end
