class MonthlyGoal < ApplicationRecord
  belongs_to :user

  validates :month, presence: true, uniqueness: { scope: :user_id }
  validates :rooms_target, :equipment_target, :food_beverage_target, :total_target,
    numericality: { greater_than_or_equal_to: 0 }
end
