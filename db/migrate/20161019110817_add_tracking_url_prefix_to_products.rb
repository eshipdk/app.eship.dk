class AddTrackingUrlPrefixToProducts < ActiveRecord::Migration
  def change
    add_column :products, :tracking_url_prefix, :string
  end
end
