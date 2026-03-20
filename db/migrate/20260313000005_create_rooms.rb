class CreateRooms < ActiveRecord::Migration[7.2]
  def change
    create_table :rooms do |t|
      t.references :cinema,    null: false, foreign_key: true
      t.string     :name,      null: false
      t.integer    :capacity,  null: false
      t.integer    :room_type, null: false, default: 0

      t.timestamps
    end

    add_index :rooms, :room_type
  end
end
