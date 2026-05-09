class HomeController < ApplicationController
  allow_unauthenticated_access only: :show

  def show
    redirect_to sources_path and return if authenticated?
  end
end
