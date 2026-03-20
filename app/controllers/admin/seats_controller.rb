module Admin
  class SeatsController < Admin::BaseController
    before_action :set_room
    before_action :set_seat, only: [:edit, :update, :destroy]

    def index
      @seats_by_row = @room.seats.order(:row_label, :seat_number).group_by(&:row_label)
    end

    # GET /admin/rooms/:room_id/seats/generate_form
    def generate_form; end

    # POST /admin/rooms/:room_id/seats/generate
    # Params: rows (e.g. "A,B,C"), seats_per_row, start_number, seat_type
    def generate
      rows        = params[:rows].to_s.upcase.split(/[\s,]+/).map(&:strip).uniq.reject(&:blank?)
      per_row     = params[:seats_per_row].to_i
      start_num   = [params[:start_number].to_i, 1].max
      seat_type   = params[:seat_type].presence_in(Seat.seat_types.keys) || "standard"

      if rows.empty? || per_row < 1 || per_row > 50
        redirect_to generate_form_admin_room_seats_path(@room),
                    alert: "Vui lòng nhập hàng ghế hợp lệ và số ghế từ 1–50."
        return
      end

      created = 0
      skipped = 0

      ActiveRecord::Base.transaction do
        rows.each do |row|
          (start_num..start_num + per_row - 1).each do |num|
            next if Seat.exists?(room_id: @room.id, row_label: row, seat_number: num)
            Seat.create!(room: @room, row_label: row, seat_number: num, seat_type: seat_type)
            created += 1
          rescue ActiveRecord::RecordInvalid
            skipped += 1
          end
        end
      end

      redirect_to admin_room_path(@room),
                  notice: "Đã tạo #{created} ghế#{skipped > 0 ? ", bỏ qua #{skipped} ghế trùng" : ""}."
    end

    def edit; end

    def update
      if @seat.update(seat_params)
        redirect_to admin_room_path(@room), notice: "Đã cập nhật ghế #{@seat.label}."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @seat.booking_seats.exists?
        redirect_to admin_room_path(@room),
                    alert: "Không thể xoá ghế #{@seat.label}: đã có lịch sử đặt vé."
        return
      end
      @seat.destroy
      redirect_to admin_room_path(@room), notice: "Đã xoá ghế #{@seat.label}."
    end

    private

    def set_room
      if params[:room_id].present?
        # Nested routes (index, generate_form, generate): URL has :room_id
        @room = Room.includes(:cinema).find(params[:room_id])
      else
        # Shallow routes (edit, update, destroy): derive room from seat
        seat  = Seat.includes(room: :cinema).find(params[:id])
        @room = seat.room
      end
      @cinema = @room.cinema
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_cinemas_path, alert: "Không tìm thấy phòng chiếu."
    end

    def set_seat
      @seat = @room.seats.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_room_path(@room), alert: "Không tìm thấy ghế."
    end

    def seat_params
      params.require(:seat).permit(:seat_type, :status)
    end
  end
end
