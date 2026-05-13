require "test_helper"

class SourceTest < ActiveSupport::TestCase
  test "auto-generates a signing secret for Cal sources on create" do
    source = users(:one).sources.create!(name: "Cal", parser_type: "cal")
    assert_predicate source.signing_secret, :present?
    assert_equal 64, source.signing_secret.length
  end

  test "auto-generates a signing secret for GitHub sources on create" do
    source = users(:one).sources.create!(name: "Repo", parser_type: "github")
    assert_predicate source.signing_secret, :present?
  end

  test "does not auto-generate a signing secret for Stripe sources" do
    source = users(:one).sources.create!(name: "Stripe", parser_type: "stripe")
    assert_nil source.signing_secret
  end

  test "does not auto-generate a signing secret for token-only parsers" do
    %w[hatchbox status_cake custom cli].each do |parser_type|
      source = users(:one).sources.create!(name: parser_type, parser_type: parser_type)
      assert_nil source.signing_secret, "expected #{parser_type} to skip auto-gen"
    end
  end

  test "does not overwrite a user-supplied signing secret on create" do
    source = users(:one).sources.create!(name: "Cal", parser_type: "cal", signing_secret: "my-own-secret")
    assert_equal "my-own-secret", source.signing_secret
  end

  test "regenerate_signing_secret replaces the existing value" do
    source = users(:one).sources.create!(name: "Cal", parser_type: "cal")
    original = source.signing_secret

    source.regenerate_signing_secret

    assert_not_equal original, source.signing_secret
    assert_predicate source.signing_secret, :present?
  end
end
