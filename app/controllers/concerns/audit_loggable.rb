# AuditLoggable — include in admin/staff base controllers to get structured
# audit logs for every mutating action.
#
# Logged to Rails.logger (routes to log/production.log in prod).
# Extend by shipping logs to a SIEM or audit table as needed.
#
# Usage:
#   class Admin::BaseController < ApplicationController
#     include AuditLoggable
#     after_action :log_audit_event, only: [:create, :update, :destroy]
#   end
module AuditLoggable
  extend ActiveSupport::Concern

  included do
    after_action :log_audit_event
  end

  private

  def log_audit_event
    return unless %w[create update destroy].include?(action_name)
    return unless current_user

    Rails.logger.info(
      "[AUDIT] " \
      "user_id=#{current_user.id} " \
      "role=#{current_user.role} " \
      "action=#{controller_name}##{action_name} " \
      "method=#{request.method} " \
      "path=#{request.path} " \
      "params=#{filtered_params} " \
      "status=#{response.status} " \
      "ip=#{request.remote_ip} " \
      "at=#{Time.current.iso8601}"
    )
  end

  def filtered_params
    request.filtered_parameters
           .except("controller", "action", "authenticity_token", "utf8")
           .to_s
  end
end
