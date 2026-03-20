class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend

  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from Pundit::NotAuthorizedError,        with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound,       with: :record_not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :phone])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :phone])
  end

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    flash[:alert] = t("pundit.#{policy_name}.#{exception.query}",
                      default: "You are not authorized to perform this action.")
    redirect_back(fallback_location: root_path)
  end

  def record_not_found(exception)
    logger.warn "[404] #{exception.class}: #{exception.message} | #{request.method} #{request.path}"
    respond_to do |format|
      format.html { render file: Rails.public_path.join("404.html"), status: :not_found, layout: false }
      format.json { render json: { error: "Not found" }, status: :not_found }
    end
  end

  def bad_request(exception)
    logger.warn "[400] ParameterMissing: #{exception.message} | #{request.path}"
    respond_to do |format|
      format.html { redirect_back fallback_location: root_path, alert: "Invalid request." }
      format.json { render json: { error: exception.message }, status: :bad_request }
    end
  end

  def after_sign_in_path_for(resource)
    if resource.admin?
      admin_root_path
    elsif resource.staff?
      staff_root_path
    else
      root_path
    end
  end
end
