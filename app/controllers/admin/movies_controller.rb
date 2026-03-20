module Admin
  class MoviesController < Admin::BaseController
    before_action :set_movie,  only: [:show, :edit, :update, :destroy]
    before_action :load_genres, only: [:new, :create, :edit, :update]

    def index
      scope = Movie.includes(:genres).order(created_at: :desc)
      scope = scope.where(status: params[:status]) if params[:status].present?
      scope = scope.where("title LIKE ?", "%#{params[:q]}%") if params[:q].present?
      @pagy, @movies = pagy(scope, items: 15)
    end

    def show
      @showtimes = @movie.showtimes.includes(room: :cinema).order(:start_time)
    end

    def new
      @movie = Movie.new
    end

    def create
      @movie = Movie.new(movie_params)
      if @movie.save
        redirect_to admin_movie_path(@movie), notice: "Đã tạo phim '#{@movie.title}'."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @movie.update(movie_params)
        redirect_to admin_movie_path(@movie), notice: "Đã cập nhật '#{@movie.title}'."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @movie.showtimes.scheduled.exists?
        redirect_to admin_movie_path(@movie),
                    alert: "Không thể xoá: phim đang có #{@movie.showtimes.scheduled.count} suất chiếu."
        return
      end
      @movie.destroy
      redirect_to admin_movies_path, notice: "Đã xoá '#{@movie.title}'."
    end

    private

    def set_movie
      @movie = Movie.includes(:genres).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_movies_path, alert: "Không tìm thấy phim."
    end

    def load_genres
      @genres = Genre.ordered
    end

    def movie_params
      params.require(:movie).permit(
        :title, :description, :duration, :release_date,
        :status, :age_rating, :trailer_url, :poster,
        genre_ids: []
      )
    end
  end
end
