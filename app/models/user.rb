class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :events, dependent: :destroy
  has_many :monthly_goals, dependent: :destroy

  enum :role, { admin: 0, staff: 1, client: 2 }, default: :client

  def visible_events
    admin? || staff? ? Event.all : events
  end

  def monthly_goal_owner
    return self unless admin? || staff?

    User.admin.order(:id).first || self
  end
end
