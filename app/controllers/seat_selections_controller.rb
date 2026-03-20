class SeatSelectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_customer!
  before_action :set_showtime

  def show
    unless @showtime.scheduled? && @showtime.start_time > Time.current
      redirect_to movie_path(@showtime.movie),
                  alert: "Suất chiếu này không còn nhận đặt vé."
      return
    end

    @seats_by_row = @showtime.room.seats
                             .order(:row_label, :seat_number)
                             .group_by(&:row_label)

    # Single query for all booked seat IDs — no N+1
    @booked_seat_ids = BookingSeat
                         .joins(:booking)
                         .where(showtime_id: @showtime.id)
                         .where.not(bookings: { status: :cancelled })
                         .pluck(:seat_id)
                         .to_set
  end

  private

  def set_showtime
    @showtime = Showtime.includes(room: :cinema, movie: :genres).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to movies_path, alert: "Không tìm thấy suất chiếu."
  end

  def ensure_customer!
    return if current_user.customer?

    redirect_to root_path, alert: "Tính năng này chỉ dành cho khách hàng."
  end
end
