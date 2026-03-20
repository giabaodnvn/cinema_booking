class Customer::BookingsController < Customer::BaseController
  before_action :set_booking, only: [:show]

  def index
    scope = policy_scope(Booking)
              .includes(showtime: [{ room: :cinema }, :movie])
              .recent

    scope = scope.where(status: params[:status]) if params[:status].in?(Booking.statuses.keys)

    @pagy, @bookings = pagy(scope, items: 10)
  end

  def show
    authorize @booking
  end

  private

  def set_booking
    # Scope to current user — prevents accessing other users' bookings
    @booking = current_user.bookings
                           .includes(
                             :payment,
                             { booking_seats: :seat },
                             showtime: [{ room: :cinema }, :movie]
                           )
                           .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to customer_bookings_path, alert: "Không tìm thấy đơn đặt vé."
  end
end
