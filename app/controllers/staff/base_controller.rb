module Staff
  class BaseController < ApplicationController
    include StaffAccessible
    include Pagy::Backend
    include AuditLoggable

    layout "staff/application"
  end
end
