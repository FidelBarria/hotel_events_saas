class AddEventTimesToRoomUsages < ActiveRecord::Migration[8.1]
  def up
    add_column :room_usages, :start_time, :string
    add_column :room_usages, :end_time, :string
  end

  def down
    remove_column :room_usages, :start_time
    remove_column :room_usages, :end_time
  end
end
