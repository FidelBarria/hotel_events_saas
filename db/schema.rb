# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_20_230000) do
  create_table "booking_services", force: :cascade do |t|
    t.integer "booking_id", null: false
    t.integer "service_id", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "service_time"
    t.date "service_date", null: false
    t.index ["booking_id", "service_id"], name: "index_booking_services_on_booking_id_and_service_id"
    t.index ["booking_id"], name: "index_booking_services_on_booking_id"
    t.index ["service_id"], name: "index_booking_services_on_service_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.integer "event_id", null: false
    t.integer "room_id", null: false
    t.datetime "start_time", null: false
    t.datetime "end_time", null: false
    t.string "status", default: "pendente", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "room_rate_type", default: "hourly", null: false
    t.index ["event_id"], name: "index_bookings_on_event_id"
    t.index ["room_id"], name: "index_bookings_on_room_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "name", null: false
    t.string "cnpj"
    t.string "phone"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cnpj"], name: "index_clients_on_cnpj", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "client_id"
    t.string "requester_name"
    t.string "requester_phone"
    t.string "requester_email"
    t.integer "attendee_count"
    t.string "setup_format"
    t.index ["client_id"], name: "index_events_on_client_id"
    t.index ["user_id"], name: "index_events_on_user_id"
  end

  create_table "room_usages", force: :cascade do |t|
    t.integer "booking_id", null: false
    t.date "service_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "start_time"
    t.string "end_time"
    t.index ["booking_id", "service_date"], name: "index_room_usages_on_booking_id_and_service_date"
    t.index ["booking_id"], name: "index_room_usages_on_booking_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.string "name"
    t.integer "capacity"
    t.decimal "hourly_rate"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "capacity_auditorium"
    t.integer "capacity_u_shape"
    t.integer "capacity_classroom"
    t.integer "capacity_round_tables"
    t.decimal "daily_rate", precision: 10, scale: 2
  end

  create_table "services", force: :cascade do |t|
    t.string "name", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category", default: "food_beverage", null: false
    t.string "service_type", default: "individual", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name"
    t.integer "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "cnpj"
    t.string "phone"
    t.index ["cnpj"], name: "index_users_on_cnpj", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "booking_services", "bookings"
  add_foreign_key "booking_services", "services"
  add_foreign_key "bookings", "events"
  add_foreign_key "bookings", "rooms"
  add_foreign_key "events", "clients"
  add_foreign_key "events", "users"
  add_foreign_key "room_usages", "bookings"
end
