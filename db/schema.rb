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

ActiveRecord::Schema[7.2].define(version: 2026_03_19_000002) do
  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "booking_seats", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.bigint "seat_id", null: false
    t.bigint "showtime_id", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id", "seat_id"], name: "index_booking_seats_on_booking_id_and_seat_id", unique: true
    t.index ["booking_id"], name: "index_booking_seats_on_booking_id"
    t.index ["seat_id"], name: "index_booking_seats_on_seat_id"
    t.index ["showtime_id", "seat_id"], name: "index_booking_seats_on_showtime_id_and_seat_id", unique: true
    t.index ["showtime_id"], name: "index_booking_seats_on_showtime_id"
  end

  create_table "bookings", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "showtime_id", null: false
    t.string "booking_code", null: false
    t.decimal "total_amount", precision: 10, scale: 2, null: false
    t.integer "booking_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "guest_name"
    t.string "guest_phone"
    t.index ["booking_code"], name: "index_bookings_on_booking_code", unique: true
    t.index ["booking_type", "created_at"], name: "index_bookings_on_booking_type_and_created_at"
    t.index ["booking_type"], name: "index_bookings_on_booking_type"
    t.index ["created_at"], name: "index_bookings_on_created_at"
    t.index ["created_by_id"], name: "index_bookings_on_created_by_id"
    t.index ["showtime_id"], name: "index_bookings_on_showtime_id"
    t.index ["status"], name: "index_bookings_on_status"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "cinemas", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "address", null: false
    t.string "city", null: false
    t.string "phone"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["city"], name: "index_cinemas_on_city"
    t.index ["status"], name: "index_cinemas_on_status"
  end

  create_table "genres", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_genres_on_name", unique: true
  end

  create_table "movie_genres", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "movie_id", null: false
    t.bigint "genre_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["genre_id"], name: "index_movie_genres_on_genre_id"
    t.index ["movie_id", "genre_id"], name: "index_movie_genres_on_movie_id_and_genre_id", unique: true
    t.index ["movie_id"], name: "index_movie_genres_on_movie_id"
  end

  create_table "movies", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.integer "duration", null: false
    t.date "release_date"
    t.integer "status", default: 0, null: false
    t.string "age_rating"
    t.string "trailer_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["release_date"], name: "index_movies_on_release_date"
    t.index ["status"], name: "index_movies_on_status"
  end

  create_table "payments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.integer "method", default: 0, null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.integer "status", default: 0, null: false
    t.datetime "paid_at"
    t.string "transaction_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_payments_on_booking_id"
    t.index ["paid_at"], name: "index_payments_on_paid_at"
    t.index ["status", "booking_id"], name: "index_payments_on_status_and_booking_id"
    t.index ["status"], name: "index_payments_on_status"
    t.index ["transaction_code"], name: "index_payments_on_transaction_code"
  end

  create_table "rooms", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "cinema_id", null: false
    t.string "name", null: false
    t.integer "capacity", null: false
    t.integer "room_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cinema_id"], name: "index_rooms_on_cinema_id"
    t.index ["room_type"], name: "index_rooms_on_room_type"
  end

  create_table "seats", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "room_id", null: false
    t.string "row_label", null: false
    t.integer "seat_number", null: false
    t.integer "seat_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id", "row_label", "seat_number"], name: "index_seats_on_room_id_and_row_label_and_seat_number", unique: true
    t.index ["room_id"], name: "index_seats_on_room_id"
    t.index ["status"], name: "index_seats_on_status"
  end

  create_table "showtimes", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "movie_id", null: false
    t.bigint "room_id", null: false
    t.datetime "start_time", null: false
    t.datetime "end_time", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["movie_id", "status"], name: "index_showtimes_on_movie_id_and_status"
    t.index ["movie_id"], name: "index_showtimes_on_movie_id"
    t.index ["room_id", "start_time"], name: "index_showtimes_on_room_id_and_start_time"
    t.index ["room_id"], name: "index_showtimes_on_room_id"
    t.index ["start_time"], name: "index_showtimes_on_start_time"
    t.index ["status", "start_time"], name: "index_showtimes_on_status_and_start_time"
    t.index ["status"], name: "index_showtimes_on_status"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name"
    t.integer "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phone"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "booking_seats", "bookings"
  add_foreign_key "booking_seats", "seats"
  add_foreign_key "booking_seats", "showtimes"
  add_foreign_key "bookings", "showtimes"
  add_foreign_key "bookings", "users"
  add_foreign_key "bookings", "users", column: "created_by_id"
  add_foreign_key "movie_genres", "genres"
  add_foreign_key "movie_genres", "movies"
  add_foreign_key "payments", "bookings"
  add_foreign_key "rooms", "cinemas"
  add_foreign_key "seats", "rooms"
  add_foreign_key "showtimes", "movies"
  add_foreign_key "showtimes", "rooms"
end
