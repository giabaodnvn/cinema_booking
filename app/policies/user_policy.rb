class UserPolicy < ApplicationPolicy
  def index?   = user.admin?
  def show?    = user.admin? || user == record
  def create?  = user.admin?
  def update?  = user.admin? || user == record
  def destroy? = user.admin? && user != record

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(id: user.id)
      end
    end
  end
end
