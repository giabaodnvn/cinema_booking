class CreateBookings < ActiveRecord::Migration[7.2]
  def change
    create_table :bookings do |t|
      t.references :user,     null: false, foreign_key: true
      t.references :showtime, null: false, foreign_key: true
      t.string     :booking_code,  null: false
      t.decimal    :total_amount,  precision: 10, scale: 2, null: false
      t.integer    :booking_type,  null: false, default: 0
      t.integer    :status,        null: false, default: 0
      t.bigint     :created_by_id

      t.timestamps
    end

    add_index :bookings, :booking_code, unique: true
    add_index :bookings, :status
    add_index :bookings, :created_by_id
    add_foreign_key :bookings, :users, column: :created_by_id
  end
end
