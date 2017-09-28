class AddEconomicDraftIdToShipments < ActiveRecord::Migration
  def change
    add_column :shipments, :economic_draft_id, :integer
  end
end
