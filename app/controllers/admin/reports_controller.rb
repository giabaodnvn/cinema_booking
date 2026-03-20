module Admin
  class ReportsController < Admin::BaseController
    def index
      @preset     = params[:preset].presence_in(%w[today 7d 30d this_month custom]) || "30d"
      @start_date, @end_date = parse_date_range

      @report = Reports::RevenueReport.new(start_date: @start_date, end_date: @end_date)
    end

    private

    def parse_date_range
      case @preset
      when "today"
        [Date.current, Date.current]
      when "7d"
        [Date.current - 6.days, Date.current]
      when "this_month"
        [Date.current.beginning_of_month, Date.current.end_of_month]
      when "custom"
        start_d = (Date.parse(params[:start_date]) rescue Date.current - 29.days)
        end_d   = (Date.parse(params[:end_date])   rescue Date.current)
        end_d   = Date.current if end_d > Date.current
        start_d = end_d - 29.days if start_d > end_d
        [start_d, end_d]
      else # 30d default
        [Date.current - 29.days, Date.current]
      end
    end
  end
end
