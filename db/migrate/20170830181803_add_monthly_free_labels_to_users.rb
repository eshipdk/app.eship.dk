class AddMonthlyFreeLabelsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :monthly_free_labels, :integer, default: 0
    add_column :users, :monthly_free_labels_expended, :integer, default: 0
  end
end
