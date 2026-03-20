module Admin
  class ShowtimesController < Admin::BaseController
    before_action :set_movie,    only: [:new, :create]
    before_action :set_showtime, only: [:show, :edit, :update, :destroy]

    def index
      scope = Showtime.includes(:movie, room: :cinema).order(start_time: :desc)
      scope = scope.where(status: params[:status])                      if params[:status].present?
      scope = scope.where(movie_id: params[:movie_id])                  if params[:movie_id].present?
      scope = scope.joins(room: :cinema).where(cinemas: { id: params[:cinema_id] }) if params[:cinema_id].present?
      if params[:date].present?
        date  = Date.parse(params[:date]) rescue Date.current
        scope = scope.where(start_time: date.all_day)
      end
      @pagy, @showtimes = pagy(scope, items: 20)
      @movies  = Movie.order(:title)
      @cinemas = Cinema.order(:name)
    end

    def show; end

    def new
      @showtime = @movie.showtimes.build
      load_form_data
    end

    def create
      @showtime = @movie.showtimes.build(showtime_params)
      if @showtime.save
        redirect_to admin_showtime_path(@showtime), notice: "Đã tạo suất chiếu."
      else
        load_form_data
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @movie = @showtime.movie
      load_form_data
    end

    def update
      if @showtime.update(showtime_params)
        redirect_to admin_showtime_path(@showtime), notice: "Đã cập nhật suất chiếu."
      else
        @movie = @showtime.movie
        load_form_data
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @showtime.bookings.active.exists?
        redirect_to admin_showtime_path(@showtime),
                    alert: "Không thể xoá: suất chiếu có #{@showtime.bookings.active.count} đơn đặt vé đang hoạt động."
        return
      end
      @showtime.destroy
      redirect_to admin_showtimes_path, notice: "Đã xoá suất chiếu."
    end

    private

    def set_movie
      @movie = Movie.find(params[:movie_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_movies_path, alert: "Không tìm thấy phim."
    end

    def set_showtime
      @showtime = Showtime.includes(:movie, room: :cinema).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_showtimes_path, alert: "Không tìm thấy suất chiếu."
    end

    def load_form_data
      @rooms   = Room.includes(:cinema).order("cinemas.name, rooms.name").joins(:cinema)
      @cinemas = Cinema.order(:name)
    end

    def showtime_params
      params.require(:showtime).permit(:room_id, :start_time, :end_time, :price, :status)
    end
  end
end
