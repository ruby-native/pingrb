module SessionTestHelper
  def sign_in_as(user)
    Current.session = user.sessions.create!

    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:pingrb_session_id] = Current.session.id
      cookies["pingrb_session_id"] = cookie_jar[:pingrb_session_id]
    end
  end

  def sign_out
    Current.session&.destroy!
    cookies.delete("pingrb_session_id")
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include SessionTestHelper
end
