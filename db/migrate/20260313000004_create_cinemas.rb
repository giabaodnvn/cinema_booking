class CreateCinemas < ActiveRecord::Migration[7.2]
  def change
    create_table :cinemas do |t|
      t.string  :name,    null: false
      t.string  :address, null: false
      t.string  :city,    null: false
      t.string  :phone
      t.integer :status,  null: false, default: 0

      t.timestamps
    end

    add_index :cinemas, :city
    add_index :cinemas, :status
  end
end
