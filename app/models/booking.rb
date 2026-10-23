class Booking < ApplicationRecord
  belongs_to :event
  belongs_to :room
  has_many :booking_services, dependent: :destroy
  has_many :room_usages, dependent: :destroy
  has_many :services, through: :booking_services
  accepts_nested_attributes_for :booking_services, allow_destroy: true

  STATUSES = %w[pendente confirmado cancelado].freeze
  ROOM_RATE_TYPES = { "hourly" => "Por hora", "daily" => "Diária" }.freeze

  validates :start_time, :end_time, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :room_rate_type, inclusion: { in: ROOM_RATE_TYPES.keys }
  validate :end_time_must_be_after_start_time
  validate :room_must_be_available

  def room_rate
    return unless room

    room.public_send(room_rate_type == "daily" ? :daily_rate : :hourly_rate)
  end

  def room_rate_units
    return 0 if start_time.blank? || end_time.blank? || end_time <= start_time

    return (end_time.to_date - start_time.to_date).to_i + 1 if room_rate_type == "daily"

    return room_usages.sum(&:billable_hours) if room_usages.exists?

    duration = end_time - start_time
    (duration / 1.hour).ceil
  end

  def room_total
    (room_rate || 0) * room_rate_units
  end

  private

  def end_time_must_be_after_start_time
    return if start_time.blank? || end_time.blank? || end_time > start_time

    errors.add(:end_time, "deve ser posterior ao horário de início")
  end

  def room_must_be_available
    return if room_id.blank? || start_time.blank? || end_time.blank? || status != "confirmado"
    return unless end_time > start_time

    conflicts = Booking.where(room_id: room_id)
      .where(status: "confirmado")
      .where("start_time < :end_time AND end_time > :start_time", start_time: start_time, end_time: end_time)
    conflicts = conflicts.where.not(id: id) if persisted?

    errors.add(:room, "já está reservada nesse intervalo") if conflicts.exists?
  end
end
