class CreateMarkupRows < ActiveRecord::Migration
  def change
    create_table :markup_rows do |t|
      t.references :cost_break, index: true, references: :interval_rows
      t.references :interval_table, index: true, references: :pricing_schemes
      t.float :markup, :default => 0
      t.boolean :active, :default => false
    end
    
    add_column :interval_rows, :default_markup, :float, :default=>0
  end
end
