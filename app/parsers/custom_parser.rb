class CustomParser < Parser
  def parse
    Result.new(
      title: payload["title"].to_s.presence || "Notification",
      body: payload["body"].to_s,
      url: payload["url"]
    )
  end
end
