class ChangeProductIdToBeStringInShipments < ActiveRecord::Migration
  def change
    change_column :shipments, :product_id, :string
  end
end
