RubyNative.configure do |c|
  c.screenshot_key = Rails.application.credentials.ruby_native&.screenshot_key

  c.screenshot_sign_in = ->(helper) {
    user = User.find_by!(email_address: "demo@example.com")
    session = user.sessions.create!(
      user_agent: helper.request.user_agent,
      ip_address: helper.request.remote_ip
    )
    helper.cookies.signed.permanent[:pingrb_session_id] = {
      value: session.id, httponly: true, same_site: :lax
    }
  }
end
