class Room < ApplicationRecord
  belongs_to :cinema
  has_many :seats, dependent: :destroy
  has_many :showtimes, dependent: :destroy

  enum :room_type, { standard: 0, vip: 1, imax: 2, couple: 3 }, default: :standard

  validates :name,      presence: true, length: { maximum: 100 }
  validates :capacity,  presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :room_type, presence: true

  scope :by_type, ->(type) { where(room_type: type) }
end
