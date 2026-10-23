class AddRoomRateTypeToBookings < ActiveRecord::Migration[8.1]
  def change
    add_column :bookings, :room_rate_type, :string, default: "hourly", null: false
  end
end
