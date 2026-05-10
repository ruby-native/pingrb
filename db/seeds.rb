user = User.find_or_initialize_by(email_address: "user@example.com")
user.password = "password"
user.password_confirmation = "password"
user.save!
puts "Seeded user: #{user.email_address}"

stripe_active = user.sources.find_or_create_by!(name: "Stripe production") do |s|
  s.parser_type = "stripe"
  s.signing_secret = "whsec_dev_active"
end

stripe_pending = user.sources.find_or_create_by!(name: "Stripe staging") do |s|
  s.parser_type = "stripe"
  s.signing_secret = "whsec_dev_pending"
end

stripe_unconfigured = user.sources.find_or_create_by!(name: "Stripe sandbox") do |s|
  s.parser_type = "stripe"
  # no signing_secret — index should show "needs setup"
end

honeybadger = user.sources.find_or_create_by!(name: "Honeybadger") do |s|
  s.parser_type = "honeybadger"
end

hatchbox = user.sources.find_or_create_by!(name: "pingrb production") do |s|
  s.parser_type = "hatchbox"
end

cal = user.sources.find_or_create_by!(name: "Cal.com") do |s|
  s.parser_type = "cal"
  s.signing_secret = "cal_dev_secret"
end

if stripe_active.notifications.empty?
  [
    [ "New payment", "$49.99 USD from joe@example.com", 2.minutes.ago ],
    [ "New payment", "$199.00 USD from indie@example.com", 3.hours.ago ],
    [ "Subscription cancelled", "leaver@example.com", 1.day.ago ],
    [ "Dispute opened", "$25.00 disputed", 2.days.ago ]
  ].each do |title, body, at|
    stripe_active.notifications.create!(title:, body:, received_at: at, raw_payload: "{}")
  end
end

if honeybadger.notifications.empty?
  [
    [ "New error", "ActiveRecord::RecordNotFound", 14.minutes.ago ],
    [ "Site down", "pingrb.com", 1.hour.ago ],
    [ "Site recovered", "pingrb.com", 58.minutes.ago ]
  ].each do |title, body, at|
    honeybadger.notifications.create!(title:, body:, received_at: at, raw_payload: "{}")
  end
end

if hatchbox.notifications.empty?
  [
    [ "Deploy failed", "main · a1b2c3d", 6.hours.ago ]
  ].each do |title, body, at|
    hatchbox.notifications.create!(title:, body:, received_at: at, raw_payload: "{}")
  end
end

if cal.notifications.empty?
  [
    [ "New booking", "Ada Lovelace · Tue Aug 11, 2:00pm", 30.minutes.ago ],
    [ "Booking cancelled", "noreply@example.com · Wed Aug 12, 9:00am", 4.hours.ago ]
  ].each do |title, body, at|
    cal.notifications.create!(title:, body:, received_at: at, raw_payload: "{}")
  end
end

puts "Seeded #{user.sources.count} sources with #{Notification.count} notifications"
