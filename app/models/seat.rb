class Seat < ApplicationRecord
  belongs_to :room
  has_many :booking_seats, dependent: :restrict_with_error
  has_many :bookings, through: :booking_seats

  enum :seat_type, { standard: 0, vip: 1, couple: 2 }, default: :standard
  enum :status,    { available: 0, maintenance: 1 },    default: :available

  validates :row_label,   presence: true, length: { maximum: 5 }
  validates :seat_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :seat_number, uniqueness: { scope: [ :room_id, :row_label ] }

  scope :available, -> { where(status: :available) }
  scope :by_row,    ->(row) { where(row_label: row).order(:seat_number) }

  def label
    "#{row_label}#{seat_number}"
  end
end
