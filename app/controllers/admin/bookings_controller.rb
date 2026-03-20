module Admin
  class BookingsController < Admin::BaseController
    before_action :set_booking, only: [:show, :mark_paid, :cancel]

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

    # PATCH /admin/bookings/:id/mark_paid
    def mark_paid
      if @booking.cancelled?
        redirect_to admin_booking_path(@booking), alert: "Vé đã huỷ, không thể xác nhận thanh toán."
        return
      end
      if @booking.payment&.completed?
        redirect_to admin_booking_path(@booking), alert: "Vé này đã được thanh toán."
        return
      end

      ActiveRecord::Base.transaction do
        @booking.payment.update!(
          status:           :completed,
          paid_at:          Time.current,
          transaction_code: @booking.payment.transaction_code.presence || "ADMIN-#{SecureRandom.hex(6).upcase}"
        )
        @booking.update!(status: :paid)
      end

      redirect_to admin_booking_path(@booking), notice: "Đã xác nhận thanh toán cho vé #{@booking.booking_code}."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_booking_path(@booking), alert: e.message
    end

    # PATCH /admin/bookings/:id/cancel
    def cancel
      if @booking.cancelled?
        redirect_to admin_booking_path(@booking), alert: "Vé đã được huỷ trước đó."
        return
      end

      @booking.update!(status: :cancelled)
      redirect_to admin_booking_path(@booking), notice: "Đã huỷ vé #{@booking.booking_code}."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_booking_path(@booking), alert: e.message
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
