class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :email
      t.string :encrypted_password
      t.string :salt
      t.column :role, :integer, default: 0
      t.string :cargoflux_api_key
      t.string :eship_api_key

      t.timestamps null: false
    end
  end
end
