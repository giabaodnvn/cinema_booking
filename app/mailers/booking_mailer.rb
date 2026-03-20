class BookingMailer < ApplicationMailer
  def booking_confirmation(booking)
    @booking  = booking
    @showtime = booking.showtime
    @movie    = @showtime.movie
    @room     = @showtime.room
    @cinema   = @room.cinema
    @seats    = booking.booking_seats.includes(:seat)
    @payment  = booking.payment

    mail(
      to:      booking.user.email,
      subject: "Xác nhận đặt vé – #{@movie.title} [#{booking.booking_code}]"
    )
  end
end
