class AllowBlankLegacyRoomEventTimes < ActiveRecord::Migration[8.1]
  def up
    change_column_null :room_usages, :start_time, true
    change_column_null :room_usages, :end_time, true
    execute "UPDATE room_usages SET start_time = NULL, end_time = NULL"
  end

  def down
    execute "UPDATE room_usages SET start_time = '09:00', end_time = '17:00' WHERE start_time IS NULL OR end_time IS NULL"
    change_column_null :room_usages, :start_time, false
    change_column_null :room_usages, :end_time, false
  end
end
