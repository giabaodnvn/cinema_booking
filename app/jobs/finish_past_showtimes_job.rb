class FinishPastShowtimesJob < ApplicationJob
  queue_as :default

  def perform
    count = Showtime.scheduled.where("end_time < ?", Time.current).update_all(status: :finished)
    Rails.logger.info "[FinishPastShowtimesJob] Marked #{count} showtime(s) as finished."
  end
end
