class AddPerformanceIndexes < ActiveRecord::Migration[7.2]
  def change
    # ── Bookings ──────────────────────────────────────────────────────────────
    add_index :bookings, :created_at,                    if_not_exists: true
    add_index :bookings, :booking_type,                  if_not_exists: true
    add_index :bookings, :status,                        if_not_exists: true
    add_index :bookings, [ :booking_type, :created_at ], if_not_exists: true
    add_index :bookings, :created_by_id,                 if_not_exists: true

    # ── Payments ──────────────────────────────────────────────────────────────
    add_index :payments, [ :status, :booking_id ], if_not_exists: true
    add_index :payments, :paid_at,                 if_not_exists: true

    # ── Showtimes ─────────────────────────────────────────────────────────────
    add_index :showtimes, [ :status, :start_time ], if_not_exists: true
    add_index :showtimes, [ :movie_id, :status ],   if_not_exists: true

    # ── Movies ────────────────────────────────────────────────────────────────
    add_index :movies, :status,       if_not_exists: true
    add_index :movies, :release_date, if_not_exists: true

    # ── Users ─────────────────────────────────────────────────────────────────
    add_index :users, :role, if_not_exists: true
  end
end
