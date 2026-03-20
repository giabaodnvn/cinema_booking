module Admin
  class GenresController < Admin::BaseController
    before_action :set_genre, only: [:edit, :update, :destroy]

    def index
      @genres = Genre.ordered.includes(:movies)
      @genre  = Genre.new
    end

    def create
      @genre = Genre.new(genre_params)
      if @genre.save
        redirect_to admin_genres_path, notice: "Đã tạo thể loại '#{@genre.name}'."
      else
        @genres = Genre.ordered.includes(:movies)
        render :index, status: :unprocessable_entity
      end
    end

    def edit
      @genres = Genre.ordered.includes(:movies)
    end

    def update
      if @genre.update(genre_params)
        redirect_to admin_genres_path, notice: "Đã cập nhật '#{@genre.name}'."
      else
        @genres = Genre.ordered.includes(:movies)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      count = @genre.movies.count
      if count > 0
        redirect_to admin_genres_path,
                    alert: "Không thể xoá: '#{@genre.name}' đang dùng cho #{count} phim."
        return
      end
      @genre.destroy
      redirect_to admin_genres_path, notice: "Đã xoá '#{@genre.name}'."
    end

    private

    def set_genre
      @genre = Genre.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_genres_path, alert: "Không tìm thấy thể loại."
    end

    def genre_params
      params.require(:genre).permit(:name)
    end
  end
end
