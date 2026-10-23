class MonthlyGoalsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_team_member

  TARGET_FIELDS = %w[rooms_target equipment_target food_beverage_target total_target].freeze

  def index
    @year = requested_year
    first_month = Date.new(@year, 1, 1)
    goal_owner = current_user.monthly_goal_owner
    existing_goals = goal_owner.monthly_goals.where(month: first_month..Date.new(@year, 12, 31)).index_by(&:month)
    @monthly_goals = (1..12).map do |month_number|
      month = Date.new(@year, month_number, 1)
      existing_goals[month] || MonthlyGoal.new(user: goal_owner, month: month)
    end
  end

  def update_year
    @year = requested_year
    submitted_goals = params.require(:goals).to_unsafe_h

    MonthlyGoal.transaction do
      @monthly_goals = (1..12).map do |month_number|
        month = Date.new(@year, month_number, 1)
        attributes = submitted_goals.fetch(month.strftime("%Y-%m"), {}).slice(*TARGET_FIELDS)
        goal = current_user.monthly_goal_owner.monthly_goals.find_or_initialize_by(month: month)
        goal.assign_attributes(attributes)
        goal.save!
        goal
      end
    end

    redirect_to monthly_goals_path(year: @year), notice: "Metas de #{@year} salvas."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to monthly_goals_path(year: @year), alert: error.record.errors.full_messages.to_sentence
  rescue ActionController::ParameterMissing
    redirect_to monthly_goals_path(year: @year), alert: "Não foi possível ler as metas enviadas."
  end

  private

  def require_team_member
    return unless current_user.client?

    redirect_to root_path, alert: "Metas estão disponíveis para a equipe do hotel."
  end

  def requested_year
    year = Integer(params[:year], 10)
    return year if year.between?(1900, 9998)

    Date.current.year
  rescue ArgumentError, TypeError
    Date.current.year
  end
end
