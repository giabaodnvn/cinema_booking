class Customer::BaseController < ApplicationController
  include Authenticatable

  before_action :ensure_customer!

  layout "application"

  private

  def ensure_customer!
    return if current_user.customer?

    flash[:alert] = "Khu vực này chỉ dành cho khách hàng."
    redirect_to root_path
  end
end
