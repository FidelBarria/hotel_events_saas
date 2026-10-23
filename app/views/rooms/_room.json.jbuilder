json.extract! room, :id, :name, :capacity, :capacity_auditorium, :capacity_u_shape, :capacity_classroom, :capacity_round_tables, :hourly_rate, :description, :created_at, :updated_at
json.url room_url(room, format: :json)
