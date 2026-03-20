class MoviesController < ApplicationController
  def index
    # Static data cached (genres & cities don't change often)
    @genres = Rails.cache.fetch("movies:genres", expires_in: 5.minutes) { Genre.ordered.to_a }
    @cities = Rails.cache.fetch("movies:cities", expires_in: 5.minutes) do
      Cinema.active.distinct.pluck(:city).sort
    end

    scope = Movie.includes(:genres)

    # Filters
    scope = scope.where(status: params[:status])           if params[:status].in?(Movie.statuses.keys)
    scope = scope.where("title LIKE ?", "%#{params[:q].strip}%") if params[:q].present?

    if params[:genre_id].present?
      scope = scope.joins(:movie_genres)
                   .where(movie_genres: { genre_id: params[:genre_id] })
                   .distinct
    end

    if params[:city].present?
      scope = scope.joins(showtimes: { room: :cinema })
                   .where(cinemas: { city: params[:city] }, showtimes: { status: :scheduled })
                   .distinct
    end

    scope = scope.order(Arel.sql("FIELD(movies.status, 'now_showing', 'upcoming', 'draft', 'ended'), movies.updated_at DESC"))

    @pagy, @movies = pagy(scope, items: 12)
  end

  def show
    @movie = Movie.includes(:genres, showtimes: { room: :cinema }).find(params[:id])

    # Use already-loaded associations; filter in Ruby to avoid extra queries
    future_showtimes = @movie.showtimes
                             .select { |s| s.scheduled? && s.start_time > Time.current }
                             .sort_by(&:start_time)

    # Single query for all booked seat counts — no N+1
    @booked_counts = if future_showtimes.any?
      BookingSeat.where(showtime_id: future_showtimes.map(&:id))
                 .group(:showtime_id)
                 .count
    else
      {}
    end

    @showtimes_by_date = future_showtimes.group_by { |s| s.start_time.to_date }
  end
end
