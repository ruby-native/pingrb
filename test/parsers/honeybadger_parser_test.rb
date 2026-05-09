require "test_helper"

class HoneybadgerParserTest < ActiveSupport::TestCase
  test "parses occurred event with fault klass" do
    result = HoneybadgerParser.parse(
      "event" => "occurred",
      "fault" => {
        "klass" => "ActiveRecord::RecordNotFound",
        "url" => "https://app.honeybadger.io/projects/1/faults/123",
        "message" => "Couldn't find User"
      },
      "project" => { "name" => "pingrb" }
    )

    assert_equal "New error", result.title
    assert_equal "ActiveRecord::RecordNotFound", result.body
    assert_equal "https://app.honeybadger.io/projects/1/faults/123", result.url
  end

  test "falls back to fault message when klass is missing" do
    result = HoneybadgerParser.parse(
      "event" => "occurred",
      "fault" => { "message" => "Something went wrong" },
      "project" => { "name" => "pingrb" }
    )

    assert_equal "Something went wrong", result.body
  end

  test "parses down event with site name and url" do
    result = HoneybadgerParser.parse(
      "event" => "down",
      "message" => "[Crywolf] GitHub is down.",
      "site" => { "name" => "GitHub", "url" => "https://github.com/" },
      "outage" => { "down_at" => "2015-03-11T22:25:40.756Z", "reason" => "Got 200" }
    )

    assert_equal "Site down", result.title
    assert_equal "[Crywolf] GitHub is down.", result.body
    assert_equal "https://github.com/", result.url
  end

  test "parses up event" do
    result = HoneybadgerParser.parse(
      "event" => "up",
      "message" => "[Crywolf] GitHub is back up after 1m 23s.",
      "site" => { "name" => "GitHub", "url" => "https://github.com/" },
      "outage" => { "up_at" => "2015-03-11T22:27:03.914Z" }
    )

    assert_equal "Site recovered", result.title
    assert_equal "[Crywolf] GitHub is back up after 1m 23s.", result.body
    assert_equal "https://github.com/", result.url
  end

  test "parses deployed event" do
    result = HoneybadgerParser.parse(
      "event" => "deployed",
      "message" => "Deploy to production by joe",
      "deploy" => { "environment" => "production", "revision" => "abc123" }
    )

    assert_equal "Deploy", result.title
    assert_equal "Deploy to production by joe", result.body
  end

  test "parses check_in_missing" do
    result = HoneybadgerParser.parse(
      "event" => "check_in_missing",
      "message" => "Daily backup did not check in",
      "check_in" => { "name" => "Daily backup" }
    )

    assert_equal "Check-in missing", result.title
    assert_equal "Daily backup did not check in", result.body
  end

  test "falls back to event name for unknown events" do
    result = HoneybadgerParser.parse("event" => "rate_limit")

    assert_equal "Honeybadger event", result.title
    assert_equal "rate_limit", result.body
  end
end
