class CreateConfigValues < ActiveRecord::Migration
  def change
    create_table :config_values do |t|
      t.string :key, unique: true
      t.string :value
    end
  end
end
