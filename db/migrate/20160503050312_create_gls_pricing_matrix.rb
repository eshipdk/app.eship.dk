class CreateGlsPricingMatrix < ActiveRecord::Migration
  def up
    
    
    create_table :pricing_schemes do |t|
      t.string :type
      t.column :pricing_type, :integer, default:1
      t.references :user, index: true, foreign_key: true
    end
    
    create_table :gls_pricing_rows do |t|
      t.string :country_code
      t.float :i0_1
      t.float :i1_5
      t.float :i5_10
      t.float :i10_15
      t.float :i15_20
      t.float :i20_30
      t.references :gls_pricing_matrix, index: true, references: :pricing_schemes
    end
    
  end
  
  def down
    drop_table :gls_pricing_rows
    drop_table :pricing_schemes
  end
end
