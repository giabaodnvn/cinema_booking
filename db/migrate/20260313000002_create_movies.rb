class CreateMovies < ActiveRecord::Migration[7.2]
  def change
    create_table :movies do |t|
      t.string  :title,       null: false
      t.text    :description
      t.integer :duration,    null: false
      t.date    :release_date
      t.integer :status,      null: false, default: 0
      t.string  :age_rating
      t.string  :trailer_url

      t.timestamps
    end

    add_index :movies, :status
    add_index :movies, :release_date
  end
end
