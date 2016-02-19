class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :email
      t.string :encrypted_password
      t.string :salt
      t.column :privilege, :integer, default: 0
      t.string :cargoflux_api_key

      t.timestamps null: false
    end
  end
end
