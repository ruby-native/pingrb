class GithubParser < Parser
  def self.verify(request, body, secret)
    GithubSignature.verify(body, request.headers["X-Hub-Signature-256"], secret)
  end

  def self.requires_signing_secret?
    true
  end

  def self.auto_generate_signing_secret?
    true
  end

  def parse
    if payload["workflow_run"]
      parse_workflow_run
    elsif payload["check_suite"]
      parse_check_suite
    elsif payload["comment"] && payload["issue"]
      parse_issue_comment
    elsif payload["issue"]
      parse_issue
    end
  end

  private

  def parse_issue
    return nil unless payload["action"] == "opened"

    issue = payload["issue"] || {}
    Result.new(
      title: "New issue",
      body: "##{issue['number']} #{issue['title']} · #{repo_name}",
      url: issue["html_url"]
    )
  end

  def parse_issue_comment
    return nil unless payload["action"] == "created"

    issue = payload["issue"] || {}
    comment = payload["comment"] || {}
    Result.new(
      title: "New comment",
      body: "#{comment.dig('user', 'login')} on ##{issue['number']} #{issue['title']}",
      url: comment["html_url"]
    )
  end

  def parse_workflow_run
    run = payload["workflow_run"] || {}
    return nil unless payload["action"] == "completed" && run["conclusion"] == "failure"

    Result.new(
      title: "CI failed",
      body: "#{run['name']} on #{run['head_branch']} · #{repo_name}",
      url: run["html_url"]
    )
  end

  def parse_check_suite
    suite = payload["check_suite"] || {}
    return nil unless payload["action"] == "completed" && suite["conclusion"] == "failure"

    Result.new(
      title: "CI failed",
      body: "#{suite['head_branch']} · #{repo_name}",
      url: payload.dig("repository", "html_url")
    )
  end

  def repo_name
    payload.dig("repository", "full_name")
  end
end
