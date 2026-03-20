class HomeController < ApplicationController
  def index
    @now_showing = Rails.cache.fetch("home:now_showing", expires_in: 5.minutes) do
      Movie.now_showing.includes(:genres).order(updated_at: :desc).limit(8).to_a
    end

    @coming_soon = Rails.cache.fetch("home:upcoming", expires_in: 5.minutes) do
      Movie.upcoming.includes(:genres).order(:release_date).limit(6).to_a
    end

    @cinemas = Rails.cache.fetch("home:cinemas", expires_in: 5.minutes) do
      Cinema.active.order(:city, :name).to_a
    end
  end
end
