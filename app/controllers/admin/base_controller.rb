module Admin
  class BaseController < ApplicationController
    include AdminAccessible
    include Pagy::Backend
    include AuditLoggable

    layout "admin/application"
  end
end
