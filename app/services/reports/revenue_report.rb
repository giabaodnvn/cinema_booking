module Reports
  class RevenueReport
    attr_reader :start_date, :end_date

    def initialize(start_date:, end_date:)
      @start_date = start_date
      @end_date   = end_date
    end

    # ── Summary stats ─────────────────────────────────────────────────

    def total_revenue
      paid_payments.sum(:amount)
    end

    def total_tickets
      BookingSeat.joins(booking: :payment)
                 .where(payments: { status: :completed })
                 .joins(:booking)
                 .where(bookings: { created_at: date_range })
                 .count
    end

    def total_bookings
      paid_payments.count
    end

    def avg_booking_value
      return 0 if total_bookings.zero?
      (total_revenue / total_bookings).round(0)
    end

    # ── Charts ────────────────────────────────────────────────────────

    # { Date => amount } — for line chart
    def revenue_by_day
      paid_payments
        .joins(:booking)
        .group_by_day("bookings.created_at", range: date_range, time_zone: "Hanoi")
        .sum(:amount)
    end

    # { "Movie title" => amount } — top 10, for bar chart
    def revenue_by_movie
      paid_payments
        .joins(booking: { showtime: :movie })
        .group("movies.title")
        .sum(:amount)
        .sort_by { |_, v| -v }
        .first(10)
        .to_h
    end

    # { "Cinema name" => amount } — for bar chart
    def revenue_by_cinema
      paid_payments
        .joins(booking: { showtime: { room: :cinema } })
        .group("cinemas.name")
        .sum(:amount)
    end

    # { "Trực tuyến" => amount, "Tại quầy" => amount } — for pie chart
    def online_vs_offline
      paid_payments
        .joins(:booking)
        .group("bookings.booking_type")
        .sum(:amount)
        .transform_keys { |k| k == "online" ? "Trực tuyến" : "Tại quầy" }
    end

    # ── Booking status breakdown ───────────────────────────────────────

    # { status => count } for ALL bookings in range (not just paid)
    def booking_status_summary
      Booking.where(created_at: date_range)
             .group(:status)
             .count
    end

    # ── Top tables ────────────────────────────────────────────────────

    # Array of [title, ticket_count, revenue] sorted by revenue desc
    def movie_table
      rows = paid_payments
               .joins(booking: { showtime: :movie })
               .group("movies.id", "movies.title")
               .select("movies.title,
                        COUNT(DISTINCT bookings.id) AS booking_count,
                        SUM(payments.amount) AS revenue")
               .map { |r| [r.title, r.booking_count.to_i, r.revenue.to_f] }
               .sort_by { |_, _, rev| -rev }
      rows.first(10)
    end

    # Array of [name, booking_count, revenue]
    def cinema_table
      paid_payments
        .joins(booking: { showtime: { room: :cinema } })
        .group("cinemas.id", "cinemas.name")
        .select("cinemas.name,
                 COUNT(DISTINCT bookings.id) AS booking_count,
                 SUM(payments.amount) AS revenue")
        .map { |r| [r.name, r.booking_count.to_i, r.revenue.to_f] }
        .sort_by { |_, _, rev| -rev }
    end

    private

    def date_range
      @date_range ||= @start_date.beginning_of_day..@end_date.end_of_day
    end

    def paid_payments
      @paid_payments ||= Payment.where(status: :completed)
                                .joins(:booking)
                                .where(bookings: { created_at: date_range })
    end
  end
end
