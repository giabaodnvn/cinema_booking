module Admin
  class UsersController < Admin::BaseController
    before_action :set_user, only: [:show, :edit, :update]

    def index
      scope = User.order(:name)
      scope = scope.where(role: params[:role]) if params[:role].present?
      scope = scope.where("name LIKE ? OR email LIKE ?", "%#{params[:q]}%", "%#{params[:q]}%") if params[:q].present?
      @pagy, @users = pagy(scope, items: 20)
    end

    def show
      @recent_bookings = @user.bookings
                              .includes(showtime: [:movie, { room: :cinema }])
                              .recent.limit(5)
    end

    def edit; end

    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "Đã cập nhật người dùng."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_users_path, alert: "Không tìm thấy người dùng."
    end

    def user_params
      params.require(:user).permit(:name, :phone, :role)
    end
  end
end
