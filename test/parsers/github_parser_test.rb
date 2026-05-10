require "test_helper"

class GithubParserTest < ActiveSupport::TestCase
  def request_with_event(event)
    headers = ActionDispatch::Http::Headers.from_hash("HTTP_X_GITHUB_EVENT" => event)
    Struct.new(:headers).new(headers)
  end

  test "parses an opened issue" do
    result = GithubParser.parse(
      {
        "action" => "opened",
        "issue" => { "number" => 42, "title" => "Webhooks broken", "html_url" => "https://github.com/foo/bar/issues/42" },
        "repository" => { "full_name" => "foo/bar" }
      },
      request: request_with_event("issues")
    )

    assert_equal "New issue", result.title
    assert_equal "foo/bar #42 · Webhooks broken", result.body
    assert_equal "https://github.com/foo/bar/issues/42", result.url
  end

  test "parses an opened pull request" do
    result = GithubParser.parse(
      {
        "action" => "opened",
        "pull_request" => { "number" => 7, "title" => "Add Cal source", "html_url" => "https://github.com/foo/bar/pull/7" },
        "repository" => { "full_name" => "foo/bar" }
      },
      request: request_with_event("pull_request")
    )

    assert_equal "New pull request", result.title
    assert_equal "foo/bar #7 · Add Cal source", result.body
  end

  test "labels merged PRs differently than closed ones" do
    merged = GithubParser.parse(
      { "action" => "closed", "pull_request" => { "number" => 7, "title" => "x", "merged" => true }, "repository" => { "full_name" => "foo/bar" } },
      request: request_with_event("pull_request")
    )
    closed = GithubParser.parse(
      { "action" => "closed", "pull_request" => { "number" => 8, "title" => "y", "merged" => false }, "repository" => { "full_name" => "foo/bar" } },
      request: request_with_event("pull_request")
    )

    assert_equal "PR merged", merged.title
    assert_equal "PR closed", closed.title
  end

  test "parses a published release" do
    result = GithubParser.parse(
      {
        "action" => "published",
        "release" => { "tag_name" => "v1.2.0", "html_url" => "https://github.com/foo/bar/releases/tag/v1.2.0" },
        "repository" => { "full_name" => "foo/bar" }
      },
      request: request_with_event("release")
    )

    assert_equal "Release published", result.title
    assert_equal "foo/bar · v1.2.0", result.body
  end

  test "parses a star" do
    result = GithubParser.parse(
      { "action" => "created", "repository" => { "full_name" => "foo/bar", "html_url" => "https://github.com/foo/bar" } },
      request: request_with_event("star")
    )

    assert_equal "New star", result.title
    assert_equal "foo/bar", result.body
  end

  test "handles the initial ping" do
    result = GithubParser.parse(
      { "zen" => "Half measures are as bad as nothing at all.", "repository" => { "full_name" => "foo/bar" } },
      request: request_with_event("ping")
    )

    assert_equal "GitHub connected", result.title
    assert_equal "foo/bar", result.body
  end
end
