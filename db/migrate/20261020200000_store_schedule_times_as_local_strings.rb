class StoreScheduleTimesAsLocalStrings < ActiveRecord::Migration[8.1]
  def up
    service_times = BookingService.find_each.to_h do |record|
      [record.id, record.service_time&.strftime("%H:%M")]
    end
    usage_times = RoomUsage.find_each.to_h do |record|
      [record.id, [record.start_time&.strftime("%H:%M"), record.end_time&.strftime("%H:%M")]]
    end

    change_column :booking_services, :service_time, :string
    change_column :room_usages, :start_time, :string
    change_column :room_usages, :end_time, :string

    service_times.each { |id, value| BookingService.where(id: id).update_all(service_time: value) }
    usage_times.each do |id, (start_time, end_time)|
      RoomUsage.where(id: id).update_all(start_time: start_time, end_time: end_time)
    end
  end

  def down
    change_column :booking_services, :service_time, :time
    change_column :room_usages, :start_time, :time
    change_column :room_usages, :end_time, :time
  end
end
