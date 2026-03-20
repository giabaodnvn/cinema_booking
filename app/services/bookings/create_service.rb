module Bookings
  # Service object that encapsulates the full booking creation flow.
  #
  # Usage (online — defaults):
  #   result = Bookings::CreateService.call(user:, showtime:, seat_ids:)
  #
  # Usage (offline counter booking):
  #   result = Bookings::CreateService.call(
  #     user:            customer_or_nil,
  #     showtime:        showtime,
  #     seat_ids:        seat_ids,
  #     booking_type:    :offline,
  #     payment_method:  :cash,       # :cash | :card
  #     payment_status:  :completed,  # paid immediately at counter
  #     created_by:      current_staff_user,
  #     guest_name:      "Nguyễn Văn A",   # for walk-in guests
  #     guest_phone:     "0901234567"
  #   )
  #
  # Race-condition strategy:
  #   1. App-level check inside a transaction (fast path).
  #   2. `showtime.with_lock` (SELECT FOR UPDATE) serialises concurrent
  #      requests for the same showtime, so the availability check is
  #      atomic for that row.
  #   3. DB unique index on booking_seats(showtime_id, seat_id) acts as
  #      the final safety net; RecordNotUnique is rescued gracefully.
  class CreateService
    MAX_SEATS = 8

    Result = Data.define(:success?, :booking, :errors)

    def self.call(**kwargs) = new(**kwargs).call

    def initialize(user:, showtime:, seat_ids:,
                   booking_type: :online,
                   payment_method: :vnpay,
                   payment_status: :pending,
                   created_by: nil,
                   guest_name: nil,
                   guest_phone: nil)
      @user           = user
      @showtime       = showtime
      @seat_ids       = Array(seat_ids).map(&:to_i).uniq
      @booking_type   = booking_type
      @payment_method = payment_method
      @payment_status = payment_status
      @created_by     = created_by || user
      @guest_name     = guest_name
      @guest_phone    = guest_phone
    end

    def call
      validate_input!

      ActiveRecord::Base.transaction do
        # Pessimistic lock on showtime row — serialises concurrent bookings
        # for the same showtime so the seat-availability check is race-safe.
        @showtime.with_lock do
          validate_showtime!
          validate_seats!

          booking = create_booking!
          create_booking_seats!(booking)
          create_payment!(booking)

          return Result.new(success?: true, booking: booking, errors: [])
        end
      end

    rescue BookingError => e
      Result.new(success?: false, booking: nil, errors: [e.message])
    rescue ActiveRecord::RecordNotUnique
      # Slip-through despite lock (shouldn't happen often, but handle it)
      Result.new(
        success?: false, booking: nil,
        errors: ["Một số ghế vừa được người khác đặt. Vui lòng chọn lại."]
      )
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, booking: nil, errors: [e.record.errors.full_messages.first])
    end

    private

    class BookingError < StandardError; end

    # ── Input validation (before hitting the DB) ──────────────────────
    def validate_input!
      raise BookingError, "Vui lòng chọn ít nhất 1 ghế." if @seat_ids.empty?
      raise BookingError, "Chỉ được chọn tối đa #{MAX_SEATS} ghế mỗi lần đặt." if @seat_ids.size > MAX_SEATS
      if @user.nil? && @guest_name.blank?
        raise BookingError, "Vui lòng nhập tên khách hàng hoặc tìm tài khoản đã đăng ký."
      end
    end

    # ── Showtime validation (inside lock) ─────────────────────────────
    def validate_showtime!
      raise BookingError, "Suất chiếu không còn nhận đặt vé."   unless @showtime.scheduled?
      raise BookingError, "Suất chiếu này đã bắt đầu hoặc kết thúc." if @showtime.start_time <= Time.current
    end

    # ── Seat validation (inside lock) ─────────────────────────────────
    def validate_seats!
      # Verify all requested seats belong to the room and are not in maintenance
      valid_ids = @showtime.room.seats.available.where(id: @seat_ids).pluck(:id)
      unless valid_ids.sort == @seat_ids.sort
        raise BookingError, "Một số ghế không hợp lệ hoặc đang bảo trì. Vui lòng chọn lại."
      end

      # Check none of the seats are already booked for this showtime
      # (excludes cancelled bookings so seats from cancelled orders are reclaimable)
      already_booked = BookingSeat
                         .joins(:booking)
                         .where(showtime_id: @showtime.id, seat_id: @seat_ids)
                         .where.not(bookings: { status: :cancelled })
                         .exists?

      raise BookingError, "Một hoặc nhiều ghế đã được đặt. Vui lòng chọn ghế khác." if already_booked
    end

    # ── Record creation ────────────────────────────────────────────────
    def create_booking!
      Booking.create!(
        user:         @user,
        showtime:     @showtime,
        total_amount: @showtime.price * @seat_ids.size,
        booking_type: @booking_type,
        status:       :pending,
        created_by:   @created_by,
        guest_name:   @guest_name,
        guest_phone:  @guest_phone
      )
    end

    def create_booking_seats!(booking)
      @seat_ids.each do |seat_id|
        BookingSeat.create!(
          booking:  booking,
          seat_id:  seat_id,
          showtime: @showtime,
          price:    @showtime.price
        )
      end
    end

    def create_payment!(booking)
      paid_at = @payment_status.to_sym == :completed ? Time.current : nil

      Payment.create!(
        booking: booking,
        method:  @payment_method,
        amount:  booking.total_amount,
        status:  @payment_status,
        paid_at: paid_at
      )
    end
  end
end
