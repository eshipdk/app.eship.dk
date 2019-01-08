class AddInternalNameAndGroupToProducts < ActiveRecord::Migration
  def change
    create_table :transporters do |t|
      t.string :name
      t.timestamps
    end
    
    add_column :products, :transporter_id, :integer, index: true
    add_foreign_key :products, :transporters, column: :transporter_id
    add_column :products, :internal_name, :string
  end
end
