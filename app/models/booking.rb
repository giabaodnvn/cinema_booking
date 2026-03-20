class Booking < ApplicationRecord
  belongs_to :user, optional: true   # nil for walk-in (offline/guest) bookings
  belongs_to :showtime
  belongs_to :created_by, class_name: "User", foreign_key: :created_by_id, optional: true
  has_many :booking_seats, dependent: :destroy
  has_many :seats, through: :booking_seats
  has_one :payment, dependent: :destroy

  enum :booking_type, { online: 0, offline: 1 }, default: :online
  enum :status,       { pending: 0, paid: 1, cancelled: 2 }, default: :pending

  validates :booking_code,  presence: true, uniqueness: true
  validates :total_amount,  presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_validation :generate_booking_code, on: :create

  scope :active,   -> { where(status: [ :pending, :paid ]) }
  scope :recent,   -> { order(created_at: :desc) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :offline_bookings, -> { where(booking_type: :offline) }

  # Human-readable customer name regardless of guest vs registered user
  def customer_display_name
    return guest_name.presence || "Khách vãng lai" if user.nil?
    user.name
  end

  def customer_display_phone
    return guest_phone.presence if user.nil?
    user.phone
  end

  private

  def generate_booking_code
    loop do
      self.booking_code = "BK#{SecureRandom.alphanumeric(8).upcase}"
      break unless Booking.exists?(booking_code: booking_code)
    end
  end
end
