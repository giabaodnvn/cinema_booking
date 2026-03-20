class CinemasController < ApplicationController
  def index
    @cinemas_by_city = Cinema.active.ordered.includes(:rooms).group_by(&:city)
    @cities = @cinemas_by_city.keys.sort
  end

  def show
    @cinema = Cinema.active.includes(rooms: :seats).find(params[:id])

    # Upcoming showtimes at this cinema, grouped by date then movie
    raw = Showtime.includes(:movie, :room)
                  .joins(:room)
                  .where(rooms: { cinema_id: @cinema.id })
                  .where(status: :scheduled)
                  .where("start_time > ?", Time.current)
                  .order(:start_time)

    @showtimes_by_date = raw.group_by { |s| s.start_time.to_date }

    # Distinct movies showing here
    @movies = raw.map(&:movie).uniq
  rescue ActiveRecord::RecordNotFound
    redirect_to cinemas_path, alert: "Không tìm thấy rạp chiếu."
  end
end
