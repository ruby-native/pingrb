require "test_helper"

class HatchboxParserTest < ActiveSupport::TestCase
  test "parses a failed deploy with branch and revision" do
    result = HatchboxParser.parse(
      "branch" => "main",
      "revision" => "a1b2c3d4e5f6",
      "log_id" => "42"
    )

    assert_equal "Deploy failed", result.title
    assert_equal "main · a1b2c3d", result.body
    assert_nil result.url
  end

  test "falls back to a generic body when fields are missing" do
    result = HatchboxParser.parse({})

    assert_equal "Deploy failed", result.title
    assert_equal "deploy failed", result.body
  end

  test "tolerates a missing branch" do
    result = HatchboxParser.parse("revision" => "abcdef1234567")

    assert_equal "abcdef1", result.body
  end
end
