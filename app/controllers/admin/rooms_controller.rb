module Admin
  class RoomsController < Admin::BaseController
    # Nested routes (index, new, create): URL has :cinema_id
    before_action :set_cinema_from_param, only: [:index, :new, :create]
    # Shallow routes (show, edit, update, destroy): URL has only :id — load cinema from room
    before_action :set_room_and_cinema, only: [:show, :edit, :update, :destroy]

    def index
      @rooms = @cinema.rooms.order(:name)
    end

    def show
      @seats_by_row = @room.seats.order(:row_label, :seat_number).group_by(&:row_label)
    end

    def new
      @room = @cinema.rooms.build
    end

    def create
      @room = @cinema.rooms.build(room_params)
      if @room.save
        redirect_to admin_room_path(@room), notice: "Đã tạo phòng '#{@room.name}'."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @room.update(room_params)
        redirect_to admin_room_path(@room), notice: "Đã cập nhật phòng '#{@room.name}'."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @room.showtimes.scheduled.exists?
        redirect_to admin_room_path(@room),
                    alert: "Không thể xoá: phòng đang có suất chiếu."
        return
      end
      @room.destroy
      redirect_to admin_cinema_path(@cinema), notice: "Đã xoá phòng '#{@room.name}'."
    end

    private

    def set_cinema_from_param
      @cinema = Cinema.find(params[:cinema_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_cinemas_path, alert: "Không tìm thấy rạp chiếu."
    end

    def set_room_and_cinema
      @room   = Room.includes(:cinema).find(params[:id])
      @cinema = @room.cinema
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_cinemas_path, alert: "Không tìm thấy phòng chiếu."
    end

    def room_params
      params.require(:room).permit(:name, :capacity, :room_type)
    end
  end
end
