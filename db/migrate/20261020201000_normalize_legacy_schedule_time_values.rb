class NormalizeLegacyScheduleTimeValues < ActiveRecord::Migration[8.1]
  def up
    normalize_column(:booking_services, :service_time)
    normalize_column(:room_usages, :start_time)
    normalize_column(:room_usages, :end_time)
  end

  def down
    # Wall-clock values should remain strings to avoid timezone conversion.
  end

  private

  def normalize_column(table, column)
    connection.select_all("SELECT id, #{column} AS value FROM #{table}").each do |row|
      value = row["value"].to_s
      next if value.blank? || value.match?(/\A\d{2}:\d{2}\z/)

      # Previous Rails TIME columns serialized local 2000-01-01 values as UTC;
      # recover the original wall clock using that date's São Paulo offset.
      time = Time.strptime(value, "%Y-%m-%d %H:%M:%S")
      local_offset = Time.new(2000, 1, 1, 0, 0, 0, "-02:00").utc_offset
      local_value = (time + local_offset).strftime("%H:%M")
      connection.execute(<<~SQL)
        UPDATE #{table} SET #{column} = #{connection.quote(local_value)} WHERE id = #{connection.quote(row["id"])}
      SQL
    end
  end
end
