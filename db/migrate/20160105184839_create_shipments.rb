class CreateShipments < ActiveRecord::Migration
  def change
    create_table :shipments do |t|
      t.references :user, index: true, foreign_key: true
      t.references :product, index: true, foreign_key: true
      t.string :request_id
      t.string :awb
      t.string :cargoflux_shipment_id
      t.string :document_url
      t.column :status, :integer, default: 0
      t.column :label_pending, :boolean, default: false
      t.column :label_pending_time, :datetime
      t.column :sender_address_id, :integer
      t.column :recipient_address_id, :integer
      t.text :api_response

      t.column :package_length, :integer
      t.column :package_width, :integer
      t.column :package_height, :integer
      t.column :package_weight, :integer
      

      t.timestamps null: false
    end
  end
end
