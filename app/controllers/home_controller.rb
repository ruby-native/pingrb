class HomeController < ApplicationController
  allow_unauthenticated_access only: %i[show privacy]

  def show
    redirect_to sources_path and return if authenticated?
  end

  def privacy
  end
end
