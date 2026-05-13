require "test_helper"

class GithubParserTest < ActiveSupport::TestCase
  test "parses an opened issue" do
    result = GithubParser.parse(
      "action" => "opened",
      "issue" => {
        "number" => 42,
        "title" => "Login is broken",
        "html_url" => "https://github.com/ruby-native/pingrb/issues/42",
        "user" => { "login" => "ada" }
      },
      "repository" => { "full_name" => "ruby-native/pingrb" }
    )

    assert_equal "New issue", result.title
    assert_equal "#42 Login is broken · ruby-native/pingrb", result.body
    assert_equal "https://github.com/ruby-native/pingrb/issues/42", result.url
  end

  test "parses a closed issue" do
    result = GithubParser.parse(
      "action" => "closed",
      "issue" => { "number" => 7, "title" => "Old bug", "html_url" => "https://example.test" },
      "repository" => { "full_name" => "ruby-native/pingrb" }
    )

    assert_equal "Issue closed", result.title
    assert_match(/^#7 Old bug · /, result.body)
  end

  test "parses a reopened issue" do
    result = GithubParser.parse(
      "action" => "reopened",
      "issue" => { "number" => 8, "title" => "Regression", "html_url" => "https://example.test" },
      "repository" => { "full_name" => "ruby-native/pingrb" }
    )

    assert_equal "Issue reopened", result.title
  end

  test "parses an assigned issue" do
    result = GithubParser.parse(
      "action" => "assigned",
      "issue" => { "number" => 9, "title" => "Triage me", "html_url" => "https://example.test" },
      "repository" => { "full_name" => "ruby-native/pingrb" }
    )

    assert_equal "Issue assigned", result.title
  end

  test "ignores unhandled issue actions" do
    result = GithubParser.parse(
      "action" => "labeled",
      "issue" => { "number" => 1, "title" => "x" },
      "repository" => { "full_name" => "r/p" }
    )

    assert_nil result
  end

  test "parses a new issue comment" do
    result = GithubParser.parse(
      "action" => "created",
      "issue" => { "number" => 12, "title" => "Discussion" },
      "comment" => {
        "html_url" => "https://github.com/ruby-native/pingrb/issues/12#issuecomment-1",
        "user" => { "login" => "grace" }
      },
      "repository" => { "full_name" => "ruby-native/pingrb" }
    )

    assert_equal "New comment", result.title
    assert_equal "grace on #12 Discussion", result.body
    assert_equal "https://github.com/ruby-native/pingrb/issues/12#issuecomment-1", result.url
  end

  test "ignores edited and deleted issue comments" do
    base = {
      "issue" => { "number" => 1, "title" => "x" },
      "comment" => { "user" => { "login" => "u" } },
      "repository" => { "full_name" => "r/p" }
    }

    assert_nil GithubParser.parse(base.merge("action" => "edited"))
    assert_nil GithubParser.parse(base.merge("action" => "deleted"))
  end

  test "parses a failed workflow run" do
    result = GithubParser.parse(
      "action" => "completed",
      "workflow_run" => {
        "name" => "CI",
        "head_branch" => "main",
        "conclusion" => "failure",
        "html_url" => "https://github.com/ruby-native/pingrb/actions/runs/1"
      },
      "repository" => { "full_name" => "ruby-native/pingrb" }
    )

    assert_equal "CI failed", result.title
    assert_equal "CI on main · ruby-native/pingrb", result.body
    assert_equal "https://github.com/ruby-native/pingrb/actions/runs/1", result.url
  end

  test "ignores a successful workflow run" do
    result = GithubParser.parse(
      "action" => "completed",
      "workflow_run" => { "name" => "CI", "head_branch" => "main", "conclusion" => "success" },
      "repository" => { "full_name" => "ruby-native/pingrb" }
    )

    assert_nil result
  end

  test "ignores in-progress workflow runs" do
    result = GithubParser.parse(
      "action" => "requested",
      "workflow_run" => { "name" => "CI", "head_branch" => "main", "conclusion" => nil },
      "repository" => { "full_name" => "ruby-native/pingrb" }
    )

    assert_nil result
  end

  test "parses a failed check suite" do
    result = GithubParser.parse(
      "action" => "completed",
      "check_suite" => { "head_branch" => "main", "conclusion" => "failure" },
      "repository" => { "full_name" => "ruby-native/pingrb", "html_url" => "https://github.com/ruby-native/pingrb" }
    )

    assert_equal "CI failed", result.title
    assert_equal "main · ruby-native/pingrb", result.body
    assert_equal "https://github.com/ruby-native/pingrb", result.url
  end

  test "ignores a successful check suite" do
    result = GithubParser.parse(
      "action" => "completed",
      "check_suite" => { "head_branch" => "main", "conclusion" => "success" },
      "repository" => { "full_name" => "ruby-native/pingrb" }
    )

    assert_nil result
  end

  test "ignores unknown events" do
    assert_nil GithubParser.parse("zen" => "Practicality beats purity.")
  end
end
