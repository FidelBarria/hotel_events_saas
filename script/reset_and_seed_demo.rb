# Apaga os dados operacionais do banco de desenvolvimento, preserva todos os
# usuarios existentes e cria um conjunto ficticio para demonstracao.
raise "Este script so pode ser executado no banco de desenvolvimento." unless Rails.env.development?

ActiveRecord::Base.transaction do
  users_before = User.order(:id).pluck(:id)
  raise "Cadastre pelo menos um usuario antes de criar os dados de demonstracao." if users_before.empty?

  FollowUpLog.delete_all
  MonthlyGoal.delete_all
  BookingService.delete_all
  RoomUsage.delete_all
  Booking.delete_all
  Event.delete_all
  Client.delete_all
  Service.delete_all
  Room.delete_all

  demo_user = User.admin.order(:id).first || User.order(:id).first
  year = Date.current.year

  rooms = [
    Room.create!(name: "Sala Horizonte", capacity: 180, capacity_auditorium: 180, capacity_u_shape: 70,
      capacity_classroom: 110, capacity_round_tables: 120, hourly_rate: 420, daily_rate: 2_800,
      description: "Sala principal para convencoes e eventos corporativos."),
    Room.create!(name: "Sala Jardim", capacity: 90, capacity_auditorium: 90, capacity_u_shape: 40,
      capacity_classroom: 60, capacity_round_tables: 70, hourly_rate: 280, daily_rate: 1_850,
      description: "Espaco versatil com luz natural."),
    Room.create!(name: "Sala Pontal", capacity: 45, capacity_auditorium: 45, capacity_u_shape: 24,
      capacity_classroom: 30, capacity_round_tables: 32, hourly_rate: 190, daily_rate: 1_250,
      description: "Sala para reunioes e treinamentos."),
    Room.create!(name: "Sala Executiva", capacity: 18, capacity_auditorium: 18, capacity_u_shape: 14,
      capacity_classroom: 12, capacity_round_tables: 16, hourly_rate: 130, daily_rate: 850,
      description: "Ambiente reservado para reunioes menores.")
  ]

  services = [
    Service.create!(name: "Coffee break executivo", price: 48, service_type: "coffee_break"),
    Service.create!(name: "Almoco buffet", price: 96, service_type: "buffet"),
    Service.create!(name: "Kit de boas-vindas", price: 32, service_type: "individual"),
    Service.create!(name: "Projetor e tela", price: 380, service_type: "equipment"),
    Service.create!(name: "Microfone sem fio", price: 140, service_type: "equipment"),
    Service.create!(name: "Sonorizacao", price: 620, service_type: "equipment")
  ]

  company_names = [
    "Aurora Tecnologia", "Grupo Vale Verde", "Instituto Caminhos", "Norte Sul Logistica",
    "Orbe Consultoria", "VivaSaude", "Ponte Alta Engenharia", "Canto do Mar Alimentos",
    "Nexo Educacao", "Horizonte Energia", "Alameda Financeira", "Casa Amora"
  ]
  contact_names = [
    "Marina Costa", "Rafael Mendes", "Camila Rocha", "Andre Lima", "Beatriz Nunes", "Felipe Azevedo",
    "Juliana Freitas", "Lucas Martins", "Renata Alves", "Gustavo Ribeiro", "Paula Teixeira", "Diego Barros"
  ]
  clients = company_names.each_with_index.map do |name, index|
    Client.create!(name: name, phone: "1199000#{format('%04d', index + 1)}",
      email: "contato#{index + 1}@exemplo.com")
  end

  statuses = %w[confirmado cotacao em_tentativa]
  created_events = []
  1.upto(12) do |month|
    3.times do |slot|
      event_date = if year == Date.current.year && month == Date.current.month
        Date.current + [0, 2, 4][slot]
      else
        Date.new(year, month, [5, 12, 20][slot])
      end
      status = statuses[slot]
      status = "pendente" if month == 11 && slot == 1
      status = "finalizado" if month == 3 && slot == 2
      status = "cancelado" if month == 7 && slot == 2
      client_index = ((month - 1) * 3 + slot) % clients.length
      attendee_count = [12, 16, 22, 28, 35, 42, 55, 68][(month + slot) % 8]
      setup_format = %w[auditorium u_shape classroom round_tables][(month + slot) % 4]
      eligible_rooms = rooms.select { |candidate| candidate.capacity_for(setup_format).to_i >= attendee_count }
      room = eligible_rooms[(month + slot) % eligible_rooms.length]
      start_at = Time.zone.local(event_date.year, event_date.month, event_date.day, 9, 0)
      end_at = Time.zone.local(event_date.year, event_date.month, event_date.day, 17, 0)

      follow_up_on = if !%w[confirmado cancelado finalizado].include?(status) &&
          ((year == Date.current.year && month == Date.current.month && slot == 1) || (month == 9 && slot == 2))
        month == 9 && slot == 2 ? Date.current - 1.day : Date.current
      end

      event = Event.create!(
        user: demo_user,
        client: clients[client_index],
        title: ["Encontro de Liderancas", "Treinamento Anual", "Apresentacao de Produtos"][slot] + " - #{clients[client_index].name}",
        description: "Evento demonstrativo para apresentar a agenda, o orcamento e a ordem de servico.",
        requester_name: contact_names[client_index],
        requester_phone: clients[client_index].phone,
        requester_email: clients[client_index].email,
        attendee_count: attendee_count,
        setup_format: setup_format,
        follow_up_on: follow_up_on
      )

      booking = event.bookings.create!(room: room, start_time: start_at, end_time: end_at,
        status: status, room_rate_type: month.even? ? "daily" : "hourly")
      booking.room_usages.create!(service_date: event_date, start_time: "09:00", end_time: "17:00")
      booking.booking_services.create!(service: services[(month + slot) % 3], quantity: attendee_count,
        service_date: event_date, service_time: "10:30")
      booking.booking_services.create!(service: services[3 + ((month + slot) % 3)], quantity: 1,
        service_date: event_date, service_time: "08:30")

      if slot == 0 && month.even?
        extra_room = (eligible_rooms - [room]).first
        if extra_room
          event.bookings.create!(room: extra_room, start_time: start_at, end_time: end_at,
            status: status, room_rate_type: "hourly")
        end
      end

      if follow_up_on
        event.follow_up_logs.create!(user: demo_user, observation: "Primeiro contato realizado; cliente solicitou o envio da proposta atualizada.",
          completed_on: follow_up_on - 3.days, next_follow_up_on: follow_up_on)
      end
      created_events << event
    end
  end

  1.upto(12) do |month|
    MonthlyGoal.create!(user: demo_user, month: Date.new(year, month, 1),
      rooms_target: 18_000 + month * 500,
      equipment_target: 7_000 + month * 250,
      food_beverage_target: 14_000 + month * 400,
      total_target: 39_000 + month * 1_150)
  end

  raise "Os usuarios foram alterados durante a carga." unless User.order(:id).pluck(:id) == users_before
  puts "Dados de demonstracao criados para #{year}: #{clients.size} clientes, #{created_events.size} eventos, #{Booking.count} reservas, #{rooms.size} salas, #{services.size} servicos, #{FollowUpLog.count} follow-ups e 12 metas mensais."
  puts "Usuarios preservados: #{users_before.size}."
end
