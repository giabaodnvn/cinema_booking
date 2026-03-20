class Genre < ApplicationRecord
  has_many :movie_genres, dependent: :destroy
  has_many :movies, through: :movie_genres

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }

  scope :ordered, -> { order(:name) }
end
