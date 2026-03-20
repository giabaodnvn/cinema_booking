class Showtime < ApplicationRecord
  belongs_to :movie
  belongs_to :room
  has_many :bookings, dependent: :restrict_with_error
  has_many :booking_seats, through: :bookings

  enum :status, { scheduled: 0, cancelled: 1, finished: 2 }, default: :scheduled

  validates :start_time, presence: true
  validates :end_time,   presence: true
  validates :price,      presence: true, numericality: { greater_than: 0 }
  validate  :end_time_after_start_time
  validate  :no_room_overlap, on: :create

  scope :available,  -> { scheduled.where("start_time > ?", Time.current) }
  scope :upcoming,   -> { scheduled.where("start_time > ?", Time.current).order(:start_time) }
  scope :today,      -> { scheduled.where(start_time: Time.current.all_day) }
  scope :for_movie,  ->(movie_id) { where(movie_id: movie_id) }

  private

  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?
    errors.add(:end_time, "must be after start time") if end_time <= start_time
  end

  def no_room_overlap
    return if start_time.blank? || end_time.blank? || room_id.blank?

    overlap = Showtime.scheduled
                      .where(room_id: room_id)
                      .where.not(id: id)
                      .where("start_time < ? AND end_time > ?", end_time, start_time)

    errors.add(:base, "Room is already booked for this time slot") if overlap.exists?
  end
end
