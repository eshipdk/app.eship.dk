class AddPasswordResetKeyToUsers < ActiveRecord::Migration
  def change
    add_column :users, :password_reset_key, :string
  end
end
