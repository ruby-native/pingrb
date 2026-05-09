user = User.find_or_initialize_by(email_address: "user@example.com")
user.password = "password"
user.password_confirmation = "password"
user.save!
puts "Seeded user: #{user.email_address}"

stripe = user.sources.find_or_create_by!(parser_type: "stripe") do |s|
  s.name = "Stripe production"
end

honeybadger = user.sources.find_or_create_by!(parser_type: "honeybadger") do |s|
  s.name = "Honeybadger"
end

if stripe.notifications.empty?
  [
    [ "New payment", "$49.99 USD from joe@example.com", 2.minutes.ago ],
    [ "New payment", "$199.00 USD from indie@example.com", 3.hours.ago ],
    [ "Subscription cancelled", "leaver@example.com", 1.day.ago ],
    [ "Dispute opened", "$25.00 disputed", 2.days.ago ]
  ].each do |title, body, at|
    stripe.notifications.create!(title:, body:, received_at: at, raw_payload: "{}")
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

puts "Seeded #{user.sources.count} sources with #{Notification.count} notifications"
