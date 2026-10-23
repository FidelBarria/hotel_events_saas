class BookingService < ApplicationRecord
  belongs_to :booking
  belongs_to :service

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :service_date, :service_time, presence: true
  validate :service_date_must_be_inside_booking

  private

  def service_date_must_be_inside_booking
    return if service_date.blank? || booking&.start_time.blank? || booking&.end_time.blank?
    return if service_date.between?(booking.start_time.to_date, booking.end_time.to_date)

    errors.add(:service_date, "deve estar dentro do período reservado da sala")
  end
end
