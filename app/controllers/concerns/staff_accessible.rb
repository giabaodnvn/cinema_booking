module StaffAccessible
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
    before_action :require_staff!
  end

  private

  def require_staff!
    unless current_user&.can_access_staff?
      flash[:alert] = "Access denied. Staff privileges required."
      redirect_to root_path
    end
  end
end
