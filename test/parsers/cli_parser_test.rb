require "test_helper"

class CliParserTest < ActiveSupport::TestCase
  test "passes title, body, and url straight through" do
    result = CliParser.parse(
      "title" => "deploy done",
      "body" => "main · a1b2c3d",
      "url" => "https://example.com/deploys/42"
    )

    assert_equal "deploy done", result.title
    assert_equal "main · a1b2c3d", result.body
    assert_equal "https://example.com/deploys/42", result.url
  end

  test "falls back to a generic title when missing" do
    result = CliParser.parse("body" => "something happened")

    assert_equal "Notification", result.title
    assert_equal "something happened", result.body
    assert_nil result.url
  end
end
