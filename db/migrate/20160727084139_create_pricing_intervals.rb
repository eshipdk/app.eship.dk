class CreatePricingIntervals < ActiveRecord::Migration
  def up
    create_table :interval_rows do |t|
      t.string :country_code
      t.float :weight_from
      t.float :weight_to
      t.float :value
      t.references :interval_table, index: true, references: :pricing_schemes
    end
  end
  
  def down
    drop_table :interval_rows
  end
end
