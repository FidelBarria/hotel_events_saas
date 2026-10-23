class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @total_rooms = Room.count
    @events_today = confirmed_bookings_for(Date.current.all_day).distinct.count(:event_id)
    visible_events = current_user.visible_events
    @pending_events = visible_events.left_outer_joins(:bookings)
      .where(bookings: { id: nil })
      .or(visible_events.left_outer_joins(:bookings).where(bookings: { status: %w[cotacao pendente em_tentativa] }))
      .distinct.count(:id)
    @follow_up_events = if current_user.admin? || current_user.staff?
      visible_events.where.not(follow_up_on: nil).where(follow_up_on: ..Date.current)
        .includes(:client, :bookings, follow_up_logs: :user).order(:follow_up_on).select(&:follow_up_active?)
    else
      []
    end

    @goal_month = requested_goal_month.beginning_of_month
    @can_view_goals = !current_user.client?
    @monthly_goal = current_user.monthly_goal_owner.monthly_goals.find_or_initialize_by(month: @goal_month)
    @chart_year = requested_chart_year
    @annual_revenue = calculate_annual_revenue(@chart_year)
    @monthly_actuals = if @goal_month.year == @chart_year
      @annual_revenue[@goal_month.month - 1][:statuses]["confirmado"]
    else
      calculate_monthly_actuals(@goal_month)
    end

    @week_start = requested_week.beginning_of_week(:monday)
    @week_end = @week_start + 6.days
    @calendar_days = (@week_start..@week_end).to_a
    @rooms = Room.order(:name)
    @selected_statuses = if params.key?(:statuses)
      Array(params[:statuses]).select { |status| Booking::STATUSES.include?(status) }
    else
      Booking::STATUSES
    end

    bookings = Booking.where(event_id: visible_events.select(:id), status: @selected_statuses)
      .where("start_time < ? AND end_time > ?", @week_end.end_of_day, @week_start.beginning_of_day)
      .includes(:event)

    @bookings_by_room_and_day = Hash.new { |hash, key| hash[key] = [] }
    bookings.each do |booking|
      @calendar_days.each do |day|
        next unless booking.start_time < day.end_of_day && booking.end_time > day.beginning_of_day

        @bookings_by_room_and_day[[booking.room_id, day]] << booking
      end
    end
  end

  private

  def confirmed_bookings_for(range)
    Booking.where(event_id: current_user.visible_events.select(:id), status: "confirmado")
      .where("start_time < ? AND end_time > ?", range.end, range.begin)
  end

  def requested_week
    return Date.current if params[:week].blank?

    Date.iso8601(params[:week])
  rescue Date::Error
    Date.current
  end

  def requested_goal_month
    return Date.current.beginning_of_month if params[:goal_month].blank?

    Date.strptime(params[:goal_month].to_s, "%Y-%m")
  rescue Date::Error, ArgumentError
    Date.current.beginning_of_month
  end

  def requested_chart_year
    year = Integer(params[:chart_year], 10)
    return year if year.between?(1900, 9998)

    Date.current.year
  rescue ArgumentError, TypeError
    Date.current.year
  end

  def calculate_annual_revenue(year)
    bookings_by_status = Booking.where(event_id: current_user.visible_events.select(:id), status: %w[confirmado cotacao em_tentativa])
      .includes(:room, :room_usages, booking_services: :service).group_by(&:status)
    (1..12).map do |month_number|
      month = Date.new(year, month_number, 1)
      statuses = %w[confirmado cotacao em_tentativa].index_with do |status|
        monthly_actuals_for(bookings_by_status.fetch(status, []), month)
      end
      { month: month, statuses: statuses }
    end
  end

  def calculate_monthly_actuals(month)
    monthly_actuals_for(confirmed_bookings, month)
  end

  def confirmed_bookings
    Booking.where(event_id: current_user.visible_events.select(:id), status: "confirmado")
      .includes(:room, :room_usages, booking_services: :service)
  end

  def monthly_actuals_for(bookings, month)
    month_start = month.beginning_of_month
    month_end = month.end_of_month
    actuals = { rooms: BigDecimal("0"), equipment: BigDecimal("0"), food_beverage: BigDecimal("0") }

    bookings.each do |booking|
      actuals[:rooms] += monthly_room_revenue(booking, month_start, month_end)
      booking.booking_services.each do |line|
        next unless line.service_date.between?(month_start, month_end)

        category = line.service.category == "equipment" ? :equipment : :food_beverage
        actuals[category] += line.service.price * line.quantity
      end
    end

    actuals[:total] = actuals[:rooms] + actuals[:equipment] + actuals[:food_beverage]
    actuals
  end

  def monthly_room_revenue(booking, month_start, month_end)
    rate = booking.room_rate || BigDecimal("0")
    return BigDecimal("0") if rate.zero?

    if booking.room_rate_type == "daily"
      first_day = [booking.start_time.to_date, month_start].max
      last_day = [booking.end_time.to_date, month_end].min
      return BigDecimal("0") if last_day < first_day

      return rate * ((last_day - first_day).to_i + 1)
    end

    usages = booking.room_usages.to_a
    if usages.any?
      return rate * usages.select { |usage| usage.service_date.between?(month_start, month_end) }.sum(&:billable_hours)
    end

    period_start = [booking.start_time, month_start.beginning_of_day].max
    period_end = [booking.end_time, month_end.end_of_day].min
    return BigDecimal("0") unless period_end > period_start

    rate * ((period_end - period_start) / 1.hour).ceil
  end
end
