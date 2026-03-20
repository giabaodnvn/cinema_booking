class CreateShowtimes < ActiveRecord::Migration[7.2]
  def change
    create_table :showtimes do |t|
      t.references :movie, null: false, foreign_key: true
      t.references :room,  null: false, foreign_key: true
      t.datetime   :start_time, null: false
      t.datetime   :end_time,   null: false
      t.decimal    :price,      precision: 10, scale: 2, null: false
      t.integer    :status,     null: false, default: 0

      t.timestamps
    end

    add_index :showtimes, :start_time
    add_index :showtimes, :status
    add_index :showtimes, [ :room_id, :start_time ]
  end
end
