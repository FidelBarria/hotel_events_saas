class Service < ApplicationRecord
  CATEGORIES = %w[food_beverage equipment].freeze
  TYPES = %w[coffee_break buffet individual equipment].freeze
  TYPE_LABELS = {
    "coffee_break" => "Coffee break",
    "buffet" => "Buffet de almoço/jantar",
    "individual" => "A&B avulso",
    "equipment" => "Equipamento"
  }.freeze

  has_many :booking_services, dependent: :destroy
  has_many :bookings, through: :booking_services

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :category, inclusion: { in: CATEGORIES }
  validates :service_type, inclusion: { in: TYPES }
  validate :category_matches_type

  before_validation :set_category_from_type

  private

  def set_category_from_type
    self.category = service_type == "equipment" ? "equipment" : "food_beverage" if service_type.present?
  end

  def category_matches_type
    return if category.blank? || service_type.blank?

    expected_category = service_type == "equipment" ? "equipment" : "food_beverage"
    errors.add(:service_type, "não corresponde à categoria") unless category == expected_category
  end
end
