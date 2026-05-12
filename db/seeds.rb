user = User.find_or_initialize_by(email_address: "user@example.com")
user.password = "password"
user.password_confirmation = "password"
user.save!
puts "Seeded user: #{user.email_address}"

sources = {
  stripe_active: user.sources.find_or_create_by!(name: "Stripe production") { |s|
    s.parser_type = "stripe"
    s.signing_secret = "whsec_dev_active"
  },
  stripe_pending: user.sources.find_or_create_by!(name: "Stripe staging") { |s|
    s.parser_type = "stripe"
    s.signing_secret = "whsec_dev_pending"
  },
  stripe_unconfigured: user.sources.find_or_create_by!(name: "Stripe sandbox") { |s|
    s.parser_type = "stripe"
  },
  hatchbox: user.sources.find_or_create_by!(name: "pingrb production") { |s|
    s.parser_type = "hatchbox"
  },
  cal: user.sources.find_or_create_by!(name: "Cal.com") { |s|
    s.parser_type = "cal"
    s.signing_secret = "cal_dev_secret"
  },
  status_cake: user.sources.find_or_create_by!(name: "pingrb monitors") { |s|
    s.parser_type = "status_cake"
  },
  custom: user.sources.find_or_create_by!(name: "Background jobs") { |s|
    s.parser_type = "custom"
  },
  cli: user.sources.find_or_create_by!(name: "terminal") { |s|
    s.parser_type = "cli"
  }
}

webhook_seeds = {
  stripe_active: [
    [ "stripe/payment_intent_succeeded.json", 2.minutes.ago ],
    [ "stripe/invoice_paid.json", 3.hours.ago ],
    [ "stripe/subscription_deleted.json", 1.day.ago ],
    [ "stripe/dispute_created.json", 2.days.ago ]
  ],
  hatchbox: [
    [ "hatchbox/deploy_failed.txt", 6.hours.ago ]
  ],
  cal: [
    [ "cal/booking_created.json", 30.minutes.ago ],
    [ "cal/booking_cancelled.json", 4.hours.ago ]
  ],
  status_cake: [
    [ "status_cake/site_down.txt", 12.minutes.ago ],
    [ "status_cake/site_recovered.txt", 9.minutes.ago ]
  ],
  custom: [
    [ "custom/job_done.json", 18.minutes.ago ],
    [ "custom/agent_error.json", 2.hours.ago ]
  ],
  cli: [
    [ "cli/deploy_done.json", 8.minutes.ago ],
    [ "cli/script_finished.json", 1.hour.ago ]
  ]
}

webhook_seeds.each do |source_key, entries|
  source = sources[source_key]
  next if source.notifications.any?

  entries.each do |fixture, received_at|
    body = File.read(Rails.root.join("db/seeds/webhooks", fixture))
    payload = fixture.end_with?(".json") ? JSON.parse(body) : Rack::Utils.parse_nested_query(body)
    result = source.parser.parse(payload)

    source.notifications.create!(
      title: result.title,
      body: result.body,
      url: result.url,
      received_at: received_at,
      raw_payload: body
    )
  end
end

puts "Seeded #{user.sources.count} sources with #{Notification.count} notifications"
