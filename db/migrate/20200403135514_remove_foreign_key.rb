class RemoveForeignKey < ActiveRecord::Migration
  def change
    remove_foreign_key "shipments", "products"
  end
end
