module Admin
  class DashboardController < Admin::BaseController
    def index
      # Users
      @users_total   = User.count
      @users_by_role = User.group(:role).count

      # Movies
      @movies_total  = Movie.count
      @movies_active = Movie.where(status: :now_showing).count

      # Showtimes
      @showtimes_today = Showtime.scheduled.where(start_time: Date.current.all_day).count
      @showtimes_week  = Showtime.scheduled
                                 .where(start_time: Time.current.beginning_of_week..Time.current.end_of_week)
                                 .count

      # Bookings
      @bookings_total   = Booking.count
      @bookings_today   = Booking.where("DATE(created_at) = ?", Date.current).count
      @pending_bookings = Booking.pending.count

      # Revenue
      @revenue_today = Payment.where(status: :completed)
                               .where("DATE(paid_at) = ?", Date.current)
                               .sum(:amount)
      @revenue_month = Payment.where(status: :completed)
                               .where(paid_at: Time.current.beginning_of_month..Time.current.end_of_month)
                               .sum(:amount)

      # Recent bookings table
      @recent_bookings = Booking.includes(:user, showtime: [:movie, { room: :cinema }])
                                .recent
                                .limit(8)
    end
  end
end
