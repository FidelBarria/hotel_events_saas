class AddDailyRateToRooms < ActiveRecord::Migration[8.1]
  def change
    add_column :rooms, :daily_rate, :decimal, precision: 10, scale: 2
  end
end
