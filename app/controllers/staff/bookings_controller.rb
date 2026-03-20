module Staff
  class BookingsController < Staff::BaseController
    before_action :set_showtime, only: [:seats, :create]
    before_action :set_booking,  only: [:show, :mark_paid, :cancel]

    # GET /staff/bookings — list today's offline bookings + quick stats
    def index
      scope = Booking.offline_bookings
                     .includes(:showtime, { showtime: [:movie, { room: :cinema }] },
                               :booking_seats, :payment)
                     .recent
      @pagy, @bookings = pagy(scope, items: 20)

      @today_count  = Booking.offline_bookings.where("DATE(created_at) = ?", Date.current).count
      @today_revenue = Booking.offline_bookings
                               .joins(:payment)
                               .where("DATE(bookings.created_at) = ?", Date.current)
                               .where(payments: { status: :completed })
                               .sum("payments.amount")
    end

    # GET /staff/bookings/new — Step 1: search showtimes
    def new
      return unless params[:q].present? || params[:date].present? || params[:cinema_id].present?

      @showtimes = Showtime.includes(:movie, room: :cinema)
                           .scheduled
                           .where("start_time > ?", Time.current)
                           .order(:start_time)

      if params[:q].present?
        @showtimes = @showtimes.joins(:movie).where("movies.title LIKE ?", "%#{params[:q]}%")
      end
      if params[:date].present?
        date = Date.parse(params[:date]) rescue Date.current
        @showtimes = @showtimes.where(start_time: date.all_day)
      end
      if params[:cinema_id].present?
        @showtimes = @showtimes.joins(room: :cinema).where(cinemas: { id: params[:cinema_id] })
      end
    end

    # GET /staff/bookings/seats?showtime_id=X — Step 2: seat map + booking form
    def seats
      unless @showtime.scheduled? && @showtime.start_time > Time.current
        redirect_to new_staff_booking_path, alert: "Suất chiếu này không còn nhận đặt vé."
        return
      end

      @seats_by_row = @showtime.room.seats
                               .order(:row_label, :seat_number)
                               .group_by(&:row_label)

      @booked_seat_ids = BookingSeat
                           .joins(:booking)
                           .where(showtime_id: @showtime.id)
                           .where.not(bookings: { status: :cancelled })
                           .pluck(:seat_id)
                           .to_set
    end

    # POST /staff/bookings — Step 3: create booking
    def create
      customer = resolve_customer

      result = Bookings::CreateService.call(
        user:           customer,
        showtime:       @showtime,
        seat_ids:       params[:seat_ids].to_a,
        booking_type:   :offline,
        payment_method: params[:payment_method]&.to_sym || :cash,
        payment_status: params[:mark_paid] == "1" ? :completed : :pending,
        created_by:     current_user,
        guest_name:     params[:guest_name].presence,
        guest_phone:    params[:guest_phone].presence
      )

      if result.success?
        redirect_to staff_booking_path(result.booking),
                    notice: "Đặt vé thành công! Mã vé: #{result.booking.booking_code}"
      else
        flash.now[:alert] = result.errors.join(", ")

        # Re-render seat map on failure
        @seats_by_row = @showtime.room.seats
                                 .order(:row_label, :seat_number)
                                 .group_by(&:row_label)

        @booked_seat_ids = BookingSeat
                             .joins(:booking)
                             .where(showtime_id: @showtime.id)
                             .where.not(bookings: { status: :cancelled })
                             .pluck(:seat_id)
                             .to_set
        render :seats, status: :unprocessable_entity
      end
    end

    # GET /staff/bookings/:id — receipt
    def show
      # @booking set by set_booking
    end

    # PATCH /staff/bookings/:id/mark_paid
    def mark_paid
      if @booking.cancelled?
        redirect_to staff_booking_path(@booking), alert: "Vé đã huỷ, không thể thu tiền."
        return
      end

      ActiveRecord::Base.transaction do
        @booking.payment.update!(status: :completed, paid_at: Time.current)
        @booking.update!(status: :paid)
      end

      redirect_to staff_booking_path(@booking), notice: "Đã xác nhận thanh toán cho vé #{@booking.booking_code}."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to staff_booking_path(@booking), alert: e.message
    end

    # PATCH /staff/bookings/:id/cancel
    def cancel
      if @booking.cancelled?
        redirect_to staff_booking_path(@booking), alert: "Vé đã được huỷ trước đó."
        return
      end

      @booking.update!(status: :cancelled)
      redirect_to staff_booking_path(@booking), notice: "Đã huỷ vé #{@booking.booking_code}."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to staff_booking_path(@booking), alert: e.message
    end

    private

    def set_showtime
      showtime_id = params[:showtime_id] || params[:booking]&.dig(:showtime_id) || params[:showtime_id]
      @showtime = Showtime.includes(room: :cinema, movie: :genres).find(showtime_id)
    rescue ActiveRecord::RecordNotFound
      redirect_to new_staff_booking_path, alert: "Không tìm thấy suất chiếu."
    end

    def set_booking
      @booking = Booking.includes(
        :payment,
        { booking_seats: :seat },
        showtime: [{ room: :cinema }, :movie]
      ).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to staff_bookings_path, alert: "Không tìm thấy đơn vé."
    end

    # Try to find existing customer by email; fall back to guest (nil)
    def resolve_customer
      email = params[:customer_email].to_s.strip
      return nil if email.blank?

      user = User.find_by(email: email)
      flash.now[:notice] = "Không tìm thấy tài khoản với email này. Đặt vé khách vãng lai." if user.nil?
      user
    end
  end
end
