require "test_helper"

class CustomParserTest < ActiveSupport::TestCase
  test "passes title, body, and url straight through" do
    result = CustomParser.parse(
      "title" => "Job done",
      "body" => "backfill finished",
      "url" => "https://example.com/jobs/42"
    )

    assert_equal "Job done", result.title
    assert_equal "backfill finished", result.body
    assert_equal "https://example.com/jobs/42", result.url
  end

  test "falls back to a generic title when missing" do
    result = CustomParser.parse("body" => "something happened")

    assert_equal "Notification", result.title
    assert_equal "something happened", result.body
    assert_nil result.url
  end

  test "treats a blank title as missing" do
    result = CustomParser.parse("title" => "", "body" => "hi")

    assert_equal "Notification", result.title
  end
end
