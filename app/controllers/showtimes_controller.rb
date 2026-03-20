class ShowtimesController < ApplicationController
  def index
    @cinemas = Cinema.active.ordered
    @movies  = Movie.where(status: [:now_showing, :upcoming]).order(:title)

    # Default to today; allow browsing up to 7 days ahead
    @selected_date = begin
      Date.parse(params[:date])
    rescue
      Date.current
    end
    @selected_date = Date.current if @selected_date < Date.current
    @date_range = (Date.current..Date.current + 6).to_a

    scope = Showtime.includes(:movie, room: :cinema)
                    .where(status: :scheduled)
                    .where(start_time: @selected_date.all_day)
                    .order(:start_time)

    scope = scope.joins(room: :cinema).where(cinemas: { id: params[:cinema_id] }) if params[:cinema_id].present?
    scope = scope.where(movie_id: params[:movie_id])                               if params[:movie_id].present?

    # Group by movie for display
    @showtimes_by_movie = scope.group_by(&:movie)
  end
end
