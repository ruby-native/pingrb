require "test_helper"

class CalParserTest < ActiveSupport::TestCase
  test "parses BOOKING_CREATED" do
    result = CalParser.parse(
      "triggerEvent" => "BOOKING_CREATED",
      "payload" => {
        "uid" => "abc123",
        "startTime" => "2026-08-21T12:00:00Z",
        "attendees" => [ { "name" => "Ada Lovelace", "email" => "ada@example.com", "timeZone" => "UTC" } ]
      }
    )

    assert_equal "New booking", result.title
    assert_match(/^Ada Lovelace · /, result.body)
    assert_equal "https://app.cal.com/booking/abc123", result.url
  end

  test "parses BOOKING_CANCELLED" do
    result = CalParser.parse(
      "triggerEvent" => "BOOKING_CANCELLED",
      "payload" => {
        "uid" => "xyz789",
        "startTime" => "2026-09-01T15:30:00Z",
        "attendees" => [ { "email" => "noname@example.com", "timeZone" => "UTC" } ]
      }
    )

    assert_equal "Booking cancelled", result.title
    assert_match(/^noname@example\.com · /, result.body)
  end

  test "falls back to event name for unknown events" do
    result = CalParser.parse("triggerEvent" => "FORM_SUBMITTED", "payload" => {})

    assert_equal "Cal.com event", result.title
    assert_equal "FORM_SUBMITTED", result.body
  end

  test "tolerates missing attendees" do
    result = CalParser.parse(
      "triggerEvent" => "BOOKING_CREATED",
      "payload" => { "uid" => "u", "startTime" => "2026-08-21T12:00:00Z", "attendees" => [] }
    )

    assert_match(/^someone · /, result.body)
  end
end
