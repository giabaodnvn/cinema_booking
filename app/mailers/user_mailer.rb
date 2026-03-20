class UserMailer < ApplicationMailer
  def welcome(user)
    @user = user

    mail(
      to:      user.email,
      subject: "Chào mừng bạn đến với CinemaBooking! 🎬"
    )
  end
end
