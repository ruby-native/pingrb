RubyNative.configure do |c|
  c.screenshot_key = Rails.application.credentials.ruby_native&.screenshot_key

  c.screenshot_sign_in = ->(controller) {
    user = User.find_by!(email_address: "demo@example.com")
    session = user.sessions.create!(
      user_agent: controller.request.user_agent,
      ip_address: controller.request.remote_ip
    )
    controller.send(:cookies).signed.permanent[:pingrb_session_id] = {
      value: session.id, httponly: true, same_site: :lax
    }
  }
end
