class Cinema < ApplicationRecord
  has_many :rooms, dependent: :destroy
  has_many :showtimes, through: :rooms

  enum :status, { active: 0, inactive: 1 }, default: :active

  validates :name,    presence: true, length: { maximum: 255 }
  validates :address, presence: true
  validates :city,    presence: true, length: { maximum: 100 }
  validates :phone,   format: { with: /\A[\d\s\-\+\(\)]{7,20}\z/ }, allow_blank: true

  scope :active,   -> { where(status: :active) }
  scope :by_city,  ->(city) { where(city: city) }
  scope :ordered,  -> { order(:name) }
end
