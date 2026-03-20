class BookingsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_customer!
  before_action :set_showtime,  only: [:create]
  before_action :set_booking,   only: [:confirmation]

  def create
    seat_ids = params[:seat_ids].to_a

    result = Bookings::CreateService.call(
      user:     current_user,
      showtime: @showtime,
      seat_ids: seat_ids
    )

    if result.success?
      redirect_to confirmation_booking_path(result.booking),
                  notice: "Đặt vé thành công! Vui lòng hoàn tất thanh toán."
    else
      redirect_to showtime_seats_path(@showtime),
                  alert: result.errors.join(", ")
    end
  end

  def confirmation
    # @booking set by set_booking
  end

  private

  def set_showtime
    @showtime = Showtime.includes(room: :cinema, movie: :genres).find(params[:showtime_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to movies_path, alert: "Không tìm thấy suất chiếu."
  end

  def set_booking
    @booking = current_user.bookings
                           .includes(
                             :payment,
                             { booking_seats: :seat },
                             showtime: [{ room: :cinema }, :movie]
                           )
                           .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to customer_bookings_path, alert: "Không tìm thấy đơn vé."
  end

  def ensure_customer!
    return if current_user.customer?

    redirect_to root_path, alert: "Tính năng này chỉ dành cho khách hàng."
  end
end
