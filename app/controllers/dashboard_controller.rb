class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @total_rooms = Room.count
    @events_today = confirmed_bookings_for(Date.current.all_day).distinct.count(:event_id)
    @pending_events = Event.left_outer_joins(:bookings)
      .where(bookings: { id: nil })
      .or(Event.left_outer_joins(:bookings).where(bookings: { status: "pendente" }))
      .distinct.count(:id)

    @week_start = requested_week.beginning_of_week(:monday)
    @week_end = @week_start + 6.days
    @calendar_days = (@week_start..@week_end).to_a
    @rooms = Room.order(:name)
    @selected_statuses = if params.key?(:statuses)
      Array(params[:statuses]).select { |status| Booking::STATUSES.include?(status) }
    else
      Booking::STATUSES
    end

    bookings = Booking.where(status: @selected_statuses)
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
    Booking.where(status: "confirmado")
      .where("start_time < ? AND end_time > ?", range.end, range.begin)
  end

  def requested_week
    return Date.current if params[:week].blank?

    Date.iso8601(params[:week])
  rescue Date::Error
    Date.current
  end
end
