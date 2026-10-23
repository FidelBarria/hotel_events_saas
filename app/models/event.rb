class Event < ApplicationRecord
  before_destroy :prevent_deletion

  belongs_to :user
  belongs_to :client
  has_many :bookings, dependent: :destroy
  has_many :follow_up_logs, dependent: :destroy

  SETUP_FORMATS = {
    "auditorium" => "Auditório",
    "u_shape" => "Formato U",
    "classroom" => "Escolar",
    "round_tables" => "Mesas redondas"
  }.freeze

  validates :title, presence: true
  validates :requester_name, :requester_phone, :requester_email, presence: true
  validates :requester_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :attendee_count, numericality: { only_integer: true, greater_than: 0 }
  validates :setup_format, inclusion: { in: SETUP_FORMATS.keys }

  def follow_up_active?
    !bookings.where(status: %w[confirmado cancelado]).exists?
  end

  private

  def prevent_deletion
    errors.add(:base, "Eventos não podem ser excluídos; altere o status da reserva.")
    throw :abort
  end
end
