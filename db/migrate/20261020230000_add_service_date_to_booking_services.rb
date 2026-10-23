class AddServiceDateToBookingServices < ActiveRecord::Migration[8.1]
  def up
    add_column :booking_services, :service_date, :date
    execute <<~SQL
      UPDATE booking_services
      SET service_date = (
        SELECT DATE(bookings.start_time)
        FROM bookings
        WHERE bookings.id = booking_services.booking_id
      )
    SQL
    change_column_null :booking_services, :service_date, false
  end

  def down
    remove_column :booking_services, :service_date
  end
end
