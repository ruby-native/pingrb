class StatusCakeParser < Parser
  def parse
    case payload["Status"].to_s.downcase
    when "down"
      Result.new(title: "Site down", body: summary, url: site_url)
    when "up"
      Result.new(title: "Site recovered", body: summary, url: site_url)
    else
      Result.new(title: "StatusCake alert", body: summary, url: site_url)
    end
  end

  private

  def site_url
    payload["URL"].presence
  end

  def summary
    name = payload["Name"].presence
    code = payload["StatusCode"].presence
    detail = code.to_s == "0" ? "timeout" : code
    [ name, site_url, detail ].compact.join(" · ")
  end
end
