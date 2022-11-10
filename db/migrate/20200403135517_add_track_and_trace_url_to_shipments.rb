class AddTrackAndTraceUrlToShipments < ActiveRecord::Migration
  def change
    add_column :shipments, :track_and_trace_url, :string
  end
end
