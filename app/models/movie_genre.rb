class MovieGenre < ApplicationRecord
  belongs_to :movie
  belongs_to :genre

  validates :genre_id, uniqueness: { scope: :movie_id, message: "already added to this movie" }
end
