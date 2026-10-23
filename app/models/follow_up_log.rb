class FollowUpLog < ApplicationRecord
  belongs_to :event
  belongs_to :user

  validates :observation, :completed_on, presence: true
end
