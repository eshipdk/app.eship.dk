class AddCreatedAtToAdditionalCharges < ActiveRecord::Migration
  def change
    add_timestamps(:additional_charges)
  end
end
