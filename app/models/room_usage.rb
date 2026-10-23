class RoomUsage < ApplicationRecord
  belongs_to :booking

  validates :service_date, :start_time, :end_time, presence: true
  validate :end_time_must_follow_start_time
  validate :date_must_be_inside_booking

  def billable_hours
    return 0 if start_time.blank? || end_time.blank?

    ((minutes(end_time) - minutes(start_time)) / 60.0).ceil
  end

  private

  def minutes(value)
    hours, minutes = value.to_s.split(":").first(2).map(&:to_i)
    hours * 60 + minutes
  end

  def end_time_must_follow_start_time
    return if start_time.blank? || end_time.blank? || minutes(end_time) > minutes(start_time)

    errors.add(:end_time, "deve ser posterior ao horário de início")
  end

  def date_must_be_inside_booking
    return if service_date.blank? || booking&.start_time.blank? || booking&.end_time.blank?
    return if service_date.between?(booking.start_time.to_date, booking.end_time.to_date)

    errors.add(:service_date, "deve estar dentro do período de utilização da sala")
  end
end
