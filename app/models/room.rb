class Room < ApplicationRecord
  SETUP_CAPACITY_COLUMNS = {
    "auditorium" => :capacity_auditorium,
    "u_shape" => :capacity_u_shape,
    "classroom" => :capacity_classroom,
    "round_tables" => :capacity_round_tables
  }.freeze

  has_many :bookings, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }
  validates :capacity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :capacity_auditorium, :capacity_u_shape, :capacity_classroom, :capacity_round_tables,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :hourly_rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :daily_rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  def capacity_for(setup_format)
    column = SETUP_CAPACITY_COLUMNS[setup_format]
    column && public_send(column)
  end
end
