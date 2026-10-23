class EventsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event, only: %i[show edit update update_schedule destroy]
  before_action :load_clients, only: %i[new create edit update]
  before_action :prepare_schedule, only: %i[show update_schedule]

  def index
    @events = current_user.events.includes(:client, bookings: [:room, :services]).order(created_at: :desc)
  end

  def show
  end

  def new
    @event = current_user.events.build
  end

  def edit
  end

  def create
    @event = current_user.events.build(event_params)
    if @event.save
      redirect_to @event, notice: "Dados iniciais do evento salvos. Agora complete a programação."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @event.update(event_params)
      redirect_to @event, notice: "Dados do evento atualizados.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def update_schedule
    permitted = schedule_params
    main_booking_attributes = (permitted[:booking_attributes] || {}).to_h
    @main_booking.assign_attributes(main_booking_attributes.except("id", "start_date", "end_date"))
    assign_booking_dates(@main_booking, main_booking_attributes)
    assign_additional_bookings(permitted[:additional_bookings_attributes] || {})
    @service_lines = submitted_service_lines(permitted[:service_lines] || {})
    @room_usages = submitted_room_usages(permitted[:room_usages] || {})
    calculate_proposal_totals

    invalid_booking = @booking_entries.find do |_key, booking|
      !booking.marked_for_destruction? && !eligible_room_ids.include?(booking.room_id)
    end
    if invalid_booking
      invalid_booking.last.errors.add(:room, "não atende à capacidade e ao formato deste evento")
      return render :show, status: :unprocessable_content
    end

    if save_schedule
      redirect_to @event, notice: "Programa e orçamento do evento salvos.", status: :see_other
    else
      render :show, status: :unprocessable_content
    end
  end

  def destroy
    @event.destroy!
    redirect_to events_path, notice: "Evento removido com sucesso.", status: :see_other
  end

  private

  def set_event
    @event = current_user.events.find(params.expect(:id))
  end

  def event_params
    params.expect(event: %i[title description client_id requester_name requester_phone requester_email attendee_count setup_format])
  end

  def schedule_params
    params.require(:event).permit(
      booking_attributes: %i[id room_id start_date end_date status room_rate_type],
      additional_bookings_attributes: %i[id room_id start_date end_date status room_rate_type _destroy],
      service_lines: {},
      room_usages: {}
    )
  end

  def submitted_service_lines(lines)
    lines.to_h.filter_map do |key, attributes|
      values = attributes.to_h
      service = @services.find_by(id: Integer(values["service_id"], 10, exception: false))
      quantity = Integer(values["quantity"], 10, exception: false)
      next unless service && quantity&.positive?

      {
        key: key.to_s,
        service: service,
        quantity: quantity,
        service_date: values["service_date"],
        service_time: values["service_time"],
        booking_key: values["booking_key"].presence || "primary"
      }
    end
  end

  def submitted_room_usages(lines)
    lines.to_h.filter_map do |key, attributes|
      values = attributes.to_h
      next if values.values_at("service_date", "start_time", "end_time").all?(&:blank?)

      { key: key.to_s, booking_key: values["booking_key"].presence || "primary",
        service_date: values["service_date"], start_time: values["start_time"], end_time: values["end_time"] }
    end
  end

  def assign_additional_bookings(bookings)
    @additional_bookings = []
    bookings.to_h.each do |key, attributes|
      values = attributes.to_h
      booking = if values["id"].present?
        @event.bookings.where.not(id: @main_booking.id).find(values["id"])
      else
        @event.bookings.build(status: "pendente")
      end
      booking.assign_attributes(values.except("id", "_destroy", "start_date", "end_date"))
      assign_booking_dates(booking, values)
      booking.mark_for_destruction if ActiveModel::Type::Boolean.new.cast(values["_destroy"])
      @additional_bookings << [key.to_s, booking]
    end
    @booking_entries = [["primary", @main_booking]] + @additional_bookings
  end

  def assign_booking_dates(booking, attributes)
    start_date = parse_booking_date(attributes["start_date"])
    end_date = parse_booking_date(attributes["end_date"])
    booking.start_time = start_date&.beginning_of_day
    booking.end_time = end_date&.end_of_day
  end

  def parse_booking_date(value)
    Date.iso8601(value) if value.present?
  rescue Date::Error
    nil
  end

  def load_clients
    @clients = Client.order(:name, :email)
  end

  def prepare_schedule
    @services = Service.order(:category, :service_type, :name)
    @eligible_rooms = eligible_rooms
    @main_booking = @event.bookings.order(:id).first || @event.bookings.build(status: "pendente")
    @additional_bookings = @event.bookings.where.not(id: @main_booking.id).order(:id).each_with_index.map do |booking, index|
      [index.to_s, booking]
    end
    @booking_entries = [["primary", @main_booking]] + @additional_bookings
    @service_lines = @booking_entries.flat_map do |key, booking|
      booking.booking_services.includes(:service).map do |line|
        { key: "existing_#{line.id}", service: line.service, quantity: line.quantity,
          service_date: line.service_date, service_time: line.service_time, booking_key: key }
      end
    end.sort_by { |line| [line[:service_date], line[:service_time].to_s] }
    @room_usages = @booking_entries.flat_map do |key, booking|
      booking.room_usages.order(:service_date).map do |usage|
        { key: "usage_#{usage.id}", booking_key: key, service_date: usage.service_date,
          start_time: usage.start_time, end_time: usage.end_time }
      end
    end
    calculate_proposal_totals
  end

  def eligible_rooms
    column = Room::SETUP_CAPACITY_COLUMNS[@event.setup_format]
    return Room.none unless column && @event.attendee_count.present?

    Room.where("#{Room.connection.quote_column_name(column)} >= ?", @event.attendee_count).order(:name)
  end

  def eligible_room_ids
    @eligible_rooms.pluck(:id)
  end

  def calculate_proposal_totals
    @food_total = @service_lines.select { |line| line[:service].category == "food_beverage" }
      .sum { |line| line[:service].price * line[:quantity] }
    @equipment_total = @service_lines.select { |line| line[:service].category == "equipment" }
      .sum { |line| line[:service].price * line[:quantity] }
    @room_total = @booking_entries.reject { |_key, booking| booking.marked_for_destruction? }
      .sum { |_key, booking| booking.room_total }
    @proposal_total = @food_total + @equipment_total + @room_total
  end

  def save_schedule
    if @service_lines.any? { |line| line[:service_date].blank? || line[:service_time].blank? }
      @event.errors.add(:base, "Informe o dia e o horário de cada serviço adicionado à proposta.")
      return false
    end
    if @room_usages.any? { |usage| usage.values_at(:service_date, :start_time, :end_time).any?(&:blank?) }
      @event.errors.add(:base, "Informe a data e os horários do evento em cada dia de utilização da sala.")
      return false
    end

    bookings_by_key = {}
    saved = true
    Event.transaction do
      @event.save!
      @booking_entries.each do |key, booking|
        if booking.marked_for_destruction?
          booking.destroy!
          next
        end

        booking.event = @event
        booking.save!
        booking.booking_services.destroy_all
        booking.room_usages.destroy_all
        bookings_by_key[key] = booking
      end

      @service_lines.each do |line|
        booking = bookings_by_key[line[:booking_key]]
        unless booking
          @event.errors.add(:base, "Selecione uma sala para cada item da proposta.")
          saved = false
          raise ActiveRecord::Rollback
        end
        booking.booking_services.create!(service: line[:service], quantity: line[:quantity],
          service_date: line[:service_date], service_time: line[:service_time])
      end

      @room_usages.each do |usage|
        booking = bookings_by_key[usage[:booking_key]]
        unless booking
          @event.errors.add(:base, "Selecione uma sala para cada horário de utilização.")
          saved = false
          raise ActiveRecord::Rollback
        end
        booking.room_usages.create!(service_date: usage[:service_date], start_time: usage[:start_time], end_time: usage[:end_time])
      end
    end
    saved && @event.errors.empty?
  rescue ActiveRecord::RecordInvalid => error
    error.record.errors.full_messages.each { |message| @event.errors.add(:base, message) }
    false
  end
end
