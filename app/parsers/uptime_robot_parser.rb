class UptimeRobotParser < Parser
  def parse
    monitor = payload["monitor"].to_s
    url = payload["url"].to_s

    case payload["type"]
    when /down/i
      Result.new(title: "Site down", body: summary(monitor, url), url: url.presence)
    when /up/i
      Result.new(title: "Site recovered", body: summary(monitor, url), url: url.presence)
    when /ssl/i
      Result.new(title: "SSL expiring", body: summary(monitor, url), url: url.presence)
    else
      Result.new(title: "UptimeRobot alert", body: summary(monitor, url).presence || payload["type"].to_s, url: url.presence)
    end
  end

  private

  def summary(monitor, url)
    [ monitor.presence, url.presence ].compact.join(" · ")
  end
end
