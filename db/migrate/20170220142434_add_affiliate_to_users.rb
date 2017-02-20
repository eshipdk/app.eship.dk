class AddAffiliateToUsers < ActiveRecord::Migration
  def up
    change_table :users do |t|
      t.references :affiliate, references: :users
    end
  end
  def down
    remove_column :users, :affiliate_id
  end
end
