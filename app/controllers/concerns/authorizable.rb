module Authorizable
  extend ActiveSupport::Concern

  included do
    helper_method :admin?
  end

  private

  def admin?
    Current.user&.admin?
  end

  def require_admin
    head :unauthorized unless admin?
  end
end
