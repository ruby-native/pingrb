user = User.find_or_initialize_by(email_address: "user@example.com")
user.password = "password"
user.password_confirmation = "password"
user.save!
puts "Seeded user: #{user.email_address}"

admin = User.find_or_initialize_by(email_address: "admin@example.com")
admin.password = "password"
admin.password_confirmation = "password"
admin.admin = true
admin.save!
puts "Seeded admin: #{admin.email_address}"

user.sources.destroy_all
user.projects.destroy_all

ruby_native = user.projects.create!(name: "ruby native")
masilotti = user.projects.create!(name: "masilotti")

sources = {
  rn_issues: user.sources.create!(name: "Ruby Native Issues", project: ruby_native, parser_type: "github", signing_secret: "github_dev_issues"),
  rn_ci: user.sources.create!(name: "Ruby Native CI", project: ruby_native, parser_type: "github", signing_secret: "github_dev_ci"),
  cli: user.sources.create!(name: "CLI", parser_type: "cli"),
  rn_uptime: user.sources.create!(name: "Ruby Native Uptime", project: ruby_native, parser_type: "status_cake"),
  meetings: user.sources.create!(name: "Scheduled Meetings", project: masilotti, parser_type: "cal", signing_secret: "cal_dev_meetings"),
  rn_deploys: user.sources.create!(name: "Ruby Native Failed Deploys", project: ruby_native, parser_type: "hatchbox"),
  masilotti_payments: user.sources.create!(name: "Payments", project: masilotti, parser_type: "stripe", signing_secret: "whsec_dev_masilotti"),
  rn_payments: user.sources.create!(name: "Ruby Native Payments", project: ruby_native, parser_type: "stripe", signing_secret: "whsec_dev_rn")
}

webhook_seeds = {
  cli: [ [ "cli/deploy_done.json", 8.minutes.ago ] ],
  rn_uptime: [ [ "status_cake/site_down.txt", 12.minutes.ago ] ],
  meetings: [ [ "cal/booking_created.json", 30.minutes.ago ] ],
  rn_deploys: [ [ "hatchbox/deploy_failed.txt", 6.hours.ago ] ]
}

webhook_seeds.each do |source_key, entries|
  source = sources[source_key]

  entries.each do |fixture, received_at|
    body = File.read(Rails.root.join("db/seeds/webhooks", fixture))
    payload = fixture.end_with?(".json") ? JSON.parse(body) : Rack::Utils.parse_nested_query(body)
    result = source.parser.parse(payload)

    source.notifications.create!(
      title: result.title,
      body: result.body,
      url: result.url,
      received_at: received_at,
      pushed_at: received_at,
      raw_payload: body
    )
  end
end

puts "Seeded #{user.sources.count} sources with #{Notification.count} notifications"
