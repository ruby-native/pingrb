require "test_helper"

class UptimeRobotParserTest < ActiveSupport::TestCase
  test "parses a Down alert" do
    result = UptimeRobotParser.parse(
      "monitor" => "pingrb.com",
      "url" => "https://pingrb.com",
      "type" => "Down",
      "details" => "Connection timeout"
    )

    assert_equal "Site down", result.title
    assert_equal "pingrb.com · https://pingrb.com", result.body
    assert_equal "https://pingrb.com", result.url
  end

  test "parses an Up alert" do
    result = UptimeRobotParser.parse(
      "monitor" => "pingrb.com",
      "url" => "https://pingrb.com",
      "type" => "Up"
    )

    assert_equal "Site recovered", result.title
  end

  test "parses an SSL Expiring alert" do
    result = UptimeRobotParser.parse(
      "monitor" => "pingrb.com",
      "url" => "https://pingrb.com",
      "type" => "SSL Expiring"
    )

    assert_equal "SSL expiring", result.title
  end

  test "falls back for unknown types" do
    result = UptimeRobotParser.parse("monitor" => "pingrb.com", "type" => "Mystery")

    assert_equal "UptimeRobot alert", result.title
    assert_equal "pingrb.com", result.body
  end
end
