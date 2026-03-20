class Movie < ApplicationRecord
  has_one_attached :poster
  has_many :movie_genres, dependent: :destroy
  has_many :genres, through: :movie_genres
  has_many :showtimes, dependent: :destroy

  enum :status, { draft: 0, upcoming: 1, now_showing: 2, ended: 3 }, default: :draft

  validates :title,    presence: true, length: { maximum: 255 }
  validates :duration, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :status,   presence: true

  scope :published,    -> { where(status: [ :upcoming, :now_showing ]) }
  scope :active,       -> { where.not(status: :draft) }
  scope :coming_soon,  -> { upcoming.where("release_date > ?", Date.current) }
  scope :by_title,     -> { order(:title) }
end
