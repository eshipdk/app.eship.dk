class AddExtrasToPricingSchemes < ActiveRecord::Migration
  def change
    add_column :pricing_schemes, :extras, :text
  end
end
