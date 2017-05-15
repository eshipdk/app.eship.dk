class AddPriceToPackages < ActiveRecord::Migration
  def change
    add_column :packages, :price, :decimal, :precision => 16, :scale => 2
    add_column :packages, :cost, :decimal, :precision => 16, :scale => 2
    add_column :packages, :title, :string
  end
end
