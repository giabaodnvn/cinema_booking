module Admin
  class CinemasController < Admin::BaseController
    before_action :set_cinema, only: [:show, :edit, :update, :destroy]

    def index
      scope = Cinema.order(:name)
      scope = scope.where(status: params[:status])         if params[:status].present?
      scope = scope.where("name LIKE ? OR city LIKE ?",
                          "%#{params[:q]}%", "%#{params[:q]}%") if params[:q].present?
      @pagy, @cinemas = pagy(scope, items: 20)
    end

    def show
      @rooms = @cinema.rooms.includes(:seats).order(:name)
    end

    def new
      @cinema = Cinema.new
    end

    def create
      @cinema = Cinema.new(cinema_params)
      if @cinema.save
        redirect_to admin_cinema_path(@cinema), notice: "Đã tạo rạp '#{@cinema.name}'."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @cinema.update(cinema_params)
        redirect_to admin_cinema_path(@cinema), notice: "Đã cập nhật '#{@cinema.name}'."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @cinema.rooms.exists?
        redirect_to admin_cinema_path(@cinema),
                    alert: "Không thể xoá: rạp đang có #{@cinema.rooms.count} phòng chiếu."
        return
      end
      @cinema.destroy
      redirect_to admin_cinemas_path, notice: "Đã xoá rạp '#{@cinema.name}'."
    end

    private

    def set_cinema
      @cinema = Cinema.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_cinemas_path, alert: "Không tìm thấy rạp chiếu."
    end

    def cinema_params
      params.require(:cinema).permit(:name, :address, :city, :phone, :status)
    end
  end
end
