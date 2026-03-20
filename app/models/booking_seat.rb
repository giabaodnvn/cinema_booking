class BookingSeat < ApplicationRecord
  belongs_to :booking
  belongs_to :seat
  belongs_to :showtime

  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :seat_id, uniqueness: { scope: :booking_id,  message: "already in this booking" }
  validates :seat_id, uniqueness: { scope: :showtime_id, message: "already booked for this showtime" }
end
