class RemoveTimesFromRoomUsages < ActiveRecord::Migration[8.1]
  def change
    remove_column :room_usages, :start_time, :string
    remove_column :room_usages, :end_time, :string
  end
end
