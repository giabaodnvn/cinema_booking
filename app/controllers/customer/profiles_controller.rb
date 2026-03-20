class Customer::ProfilesController < Customer::BaseController
  def show
    @user = current_user

    @stats = {
      total:    current_user.bookings.count,
      paid:     current_user.bookings.paid.count,
      pending:  current_user.bookings.pending.count,
      spent:    current_user.bookings.paid.sum(:total_amount)
    }

    @recent_bookings = current_user.bookings
                                   .includes(showtime: [{ room: :cinema }, :movie])
                                   .recent
                                   .limit(5)
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(profile_params)
      redirect_to customer_profile_path, notice: "Cập nhật thông tin thành công."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name, :phone)
  end
end
