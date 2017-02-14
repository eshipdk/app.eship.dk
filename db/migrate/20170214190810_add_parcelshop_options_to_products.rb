class AddParcelshopOptionsToProducts < ActiveRecord::Migration
  def change
    add_column :products, :has_parcelshops, :boolean, default: false
    add_column :products, :find_parcelshop_url, :string
  end
end
