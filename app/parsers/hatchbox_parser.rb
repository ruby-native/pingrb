class HatchboxParser < Parser
  def parse
    branch = payload["branch"].to_s
    revision = payload["revision"].to_s
    short_sha = revision[0, 7]

    body = [ branch.presence, short_sha.presence ].compact.join(" · ")
    body = "deploy failed" if body.blank?

    Result.new(title: "Deploy failed", body: body)
  end
end
