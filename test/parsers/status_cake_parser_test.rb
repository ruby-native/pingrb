require "test_helper"

class StatusCakeParserTest < ActiveSupport::TestCase
  test "parses a Down alert with name, URL, and status code" do
    result = StatusCakeParser.parse(
      "Status" => "Down",
      "URL" => "https://pingrb.com",
      "Name" => "pingrb.com",
      "StatusCode" => "503"
    )

    assert_equal "Site down", result.title
    assert_equal "pingrb.com · https://pingrb.com · 503", result.body
    assert_equal "https://pingrb.com", result.url
  end

  test "treats StatusCode 0 as timeout" do
    result = StatusCakeParser.parse(
      "Status" => "Down",
      "URL" => "https://pingrb.com",
      "Name" => "pingrb.com",
      "StatusCode" => "0"
    )

    assert_equal "pingrb.com · https://pingrb.com · timeout", result.body
  end

  test "parses an Up alert" do
    result = StatusCakeParser.parse(
      "Status" => "Up",
      "URL" => "https://pingrb.com",
      "Name" => "pingrb.com",
      "StatusCode" => "200"
    )

    assert_equal "Site recovered", result.title
    assert_equal "pingrb.com · https://pingrb.com · 200", result.body
  end

  test "falls back to a generic title for unknown statuses" do
    result = StatusCakeParser.parse("Status" => "Pending", "URL" => "https://pingrb.com")

    assert_equal "StatusCake alert", result.title
  end
end
