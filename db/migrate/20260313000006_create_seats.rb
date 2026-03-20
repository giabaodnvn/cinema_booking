class CreateSeats < ActiveRecord::Migration[7.2]
  def change
    create_table :seats do |t|
      t.references :room,        null: false, foreign_key: true
      t.string     :row_label,   null: false
      t.integer    :seat_number, null: false
      t.integer    :seat_type,   null: false, default: 0
      t.integer    :status,      null: false, default: 0

      t.timestamps
    end

    add_index :seats, [ :room_id, :row_label, :seat_number ], unique: true
    add_index :seats, :status
  end
end
