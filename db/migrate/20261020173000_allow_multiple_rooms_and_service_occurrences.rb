class AllowMultipleRoomsAndServiceOccurrences < ActiveRecord::Migration[8.1]
  def up
    remove_index :bookings, name: "index_bookings_on_event_id"
    add_index :bookings, :event_id

    remove_index :booking_services, name: "index_booking_services_on_booking_id_and_service_id"
    add_index :booking_services, [:booking_id, :service_id]
  end

  def down
    remove_index :bookings, :event_id
    add_index :bookings, :event_id, unique: true, name: "index_bookings_on_event_id"

    remove_index :booking_services, name: "index_booking_services_on_booking_id_and_service_id"
    add_index :booking_services, [:booking_id, :service_id], unique: true, name: "index_booking_services_on_booking_id_and_service_id"
  end
end
