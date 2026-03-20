class CreateBookingSeats < ActiveRecord::Migration[7.2]
  def change
    create_table :booking_seats do |t|
      t.references :booking,  null: false, foreign_key: true
      t.references :seat,     null: false, foreign_key: true
      t.references :showtime, null: false, foreign_key: true
      t.decimal    :price,    precision: 10, scale: 2, null: false

      t.timestamps
    end

    # Prevent duplicate seat in same booking
    add_index :booking_seats, [ :booking_id, :seat_id ], unique: true
    # Prevent double-booking same seat for same showtime
    add_index :booking_seats, [ :showtime_id, :seat_id ], unique: true
  end
end
