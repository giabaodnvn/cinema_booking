class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAILER_FROM", "no-reply@cinemabooking.com") }
  layout "mailer"
end
