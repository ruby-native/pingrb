class HoneybadgerParser < Parser
  def parse
    case payload["event"]
    when "occurred"
      fault = payload["fault"] || {}
      Result.new(
        title: "New error",
        body: fault["klass"] || fault["message"] || "Error in #{payload.dig('project', 'name')}",
        url: fault["url"]
      )
    when "down"
      Result.new(
        title: "Site down",
        body: payload["message"] || payload.dig("site", "name") || "Site is unreachable",
        url: payload.dig("site", "url")
      )
    when "up"
      Result.new(
        title: "Site recovered",
        body: payload["message"] || payload.dig("site", "name") || "Site is back online",
        url: payload.dig("site", "url")
      )
    when "deployed"
      deploy = payload["deploy"] || {}
      Result.new(
        title: "Deploy",
        body: payload["message"] || "#{deploy['environment']} #{deploy['revision']}".strip
      )
    when "check_in_missing"
      Result.new(
        title: "Check-in missing",
        body: payload["message"] || payload.dig("check_in", "name") || "A check-in did not report"
      )
    else
      Result.new(title: "Honeybadger event", body: payload["event"].to_s)
    end
  end
end
