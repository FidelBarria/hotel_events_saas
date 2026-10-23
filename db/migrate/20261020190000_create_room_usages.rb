class CreateRoomUsages < ActiveRecord::Migration[8.1]
  def change
    create_table :room_usages do |t|
      t.references :booking, null: false, foreign_key: true
      t.date :service_date, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.timestamps
    end

    add_index :room_usages, [:booking_id, :service_date]
  end
end
