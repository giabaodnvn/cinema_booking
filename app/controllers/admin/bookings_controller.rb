module Admin
  class BookingsController < Admin::BaseController
    before_action :set_booking, only: [:show]

    # GET /admin/bookings
    def index
      @bookings = Booking.includes(
        :user, :created_by, :payment,
        { booking_seats: :seat },
        showtime: [{ room: :cinema }, :movie]
      ).recent

      # Filters
      @bookings = @bookings.where(booking_type: params[:booking_type]) if params[:booking_type].present?
      @bookings = @bookings.where(status: params[:status])             if params[:status].present?
      if params[:date].present?
        date = Date.parse(params[:date]) rescue Date.current
        @bookings = @bookings.where(created_at: date.all_day)
      end
      if params[:q].present?
        @bookings = @bookings.where(
          "bookings.booking_code LIKE :q OR bookings.guest_name LIKE :q",
          q: "%#{params[:q]}%"
        ).or(
          Booking.joins(:user).where("users.email LIKE :q OR users.name LIKE :q", q: "%#{params[:q]}%")
        )
      end

      @pagy, @bookings = pagy(@bookings, items: 25)

      @total_count    = Booking.count
      @online_count   = Booking.online.count
      @offline_count  = Booking.offline_bookings.count
      @today_revenue  = Booking.joins(:payment)
                                .where("DATE(bookings.created_at) = ?", Date.current)
                                .where(payments: { status: :completed })
                                .sum("payments.amount")
    end

    # GET /admin/bookings/:id
    def show
      # @booking set by set_booking
    end

    private

    def set_booking
      @booking = Booking.includes(
        :user, :created_by, :payment,
        { booking_seats: :seat },
        showtime: [{ room: :cinema }, :movie]
      ).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_bookings_path, alert: "Không tìm thấy đơn vé."
    end
  end
end
