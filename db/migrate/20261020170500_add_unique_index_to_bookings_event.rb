class AddUniqueIndexToBookingsEvent < ActiveRecord::Migration[8.1]
  def change
    remove_index :bookings, :event_id
    add_index :bookings, :event_id, unique: true
  end
end
