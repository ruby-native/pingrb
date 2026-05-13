class HomeController < ApplicationController
  allow_unauthenticated_access only: %i[show privacy support]

  def show
    redirect_to sources_path and return if authenticated?
  end

  def privacy
  end

  def support
  end
end
