class GithubParser < Parser
  def self.verify(request, body, secret)
    GithubSignature.verify(body, request.headers["X-Hub-Signature-256"], secret)
  end

  def self.requires_signing_secret?
    true
  end

  def parse
    case event
    when "issues"
      issue_event
    when "pull_request"
      pull_request_event
    when "release"
      release_event
    when "star"
      star_event
    when "ping"
      Result.new(title: "GitHub connected", body: repo)
    else
      Result.new(title: "GitHub event", body: event.to_s)
    end
  end

  private

  def event
    request&.headers&.[]("X-GitHub-Event")
  end

  def repo
    payload.dig("repository", "full_name").to_s
  end

  def issue_event
    issue = payload["issue"] || {}
    case payload["action"]
    when "opened"
      Result.new(title: "New issue", body: "#{repo} ##{issue['number']} · #{issue['title']}", url: issue["html_url"])
    when "closed"
      Result.new(title: "Issue closed", body: "#{repo} ##{issue['number']} · #{issue['title']}", url: issue["html_url"])
    when "reopened"
      Result.new(title: "Issue reopened", body: "#{repo} ##{issue['number']} · #{issue['title']}", url: issue["html_url"])
    else
      Result.new(title: "Issue #{payload['action']}", body: "#{repo} ##{issue['number']} · #{issue['title']}", url: issue["html_url"])
    end
  end

  def pull_request_event
    pr = payload["pull_request"] || {}
    case payload["action"]
    when "opened"
      Result.new(title: "New pull request", body: "#{repo} ##{pr['number']} · #{pr['title']}", url: pr["html_url"])
    when "closed"
      title = pr["merged"] ? "PR merged" : "PR closed"
      Result.new(title: title, body: "#{repo} ##{pr['number']} · #{pr['title']}", url: pr["html_url"])
    else
      Result.new(title: "PR #{payload['action']}", body: "#{repo} ##{pr['number']} · #{pr['title']}", url: pr["html_url"])
    end
  end

  def release_event
    release = payload["release"] || {}
    Result.new(
      title: payload["action"] == "published" ? "Release published" : "Release #{payload['action']}",
      body: "#{repo} · #{release['tag_name']}",
      url: release["html_url"]
    )
  end

  def star_event
    return Result.new(title: "Star removed", body: repo) if payload["action"] == "deleted"
    Result.new(title: "New star", body: repo, url: payload.dig("repository", "html_url"))
  end
end
