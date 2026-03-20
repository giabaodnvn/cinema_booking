class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { customer: 0, staff: 1, admin: 2 }, default: :customer

  has_many :bookings, dependent: :restrict_with_error
  has_many :created_bookings, class_name: "Booking", foreign_key: :created_by_id, dependent: :nullify

  validates :name, presence: true
  validates :phone, format: { with: /\A[\d\s\-\+\(\)]{7,20}\z/ }, allow_blank: true

  # Role helpers
  def customer? = role == "customer"
  def staff?    = role == "staff"
  def admin?    = role == "admin"

  def can_access_admin?
    admin?
  end

  def can_access_staff?
    staff? || admin?
  end
end
