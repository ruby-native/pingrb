class AccountsController < ApplicationController
  def show
  end

  def destroy
    current_user.destroy
    cookies.delete(:pingrb_session_id)
    redirect_to new_session_path, notice: "Account deleted.", status: :see_other
  end
end
