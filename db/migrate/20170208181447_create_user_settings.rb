class CreateUserSettings < ActiveRecord::Migration
  def change
    create_table :user_settings do |t|
      t.references :user, index: true, foreign_key: true
      t.float :package_length
      t.float :package_width
      t.float :package_height
      t.float :package_weight
    end
  end
end
