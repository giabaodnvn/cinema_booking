class BookingPolicy < ApplicationPolicy
  # Admin/staff see all bookings; customer only sees their own
  class Scope < Scope
    def resolve
      if user.admin? || user.staff?
        scope.all
      else
        scope.where(user: user)
      end
    end
  end

  def index?
    user.present?
  end

  def show?
    user.admin? || user.staff? || record.user_id == user.id
  end

  def create?
    user.present?
  end

  # Customers may cancel only their own pending bookings
  def cancel?
    user.admin? || user.staff? || (record.user_id == user.id && record.pending?)
  end
end
