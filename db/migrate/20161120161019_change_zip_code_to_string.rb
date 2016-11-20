class ChangeZipCodeToString < ActiveRecord::Migration
  def up
    change_column :addresses, :zip_code, :string
  end
  
  def down
    change_column :addresses, :zip_code, :integer
  end
end
