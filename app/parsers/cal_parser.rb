class CalParser < Parser
  def self.verify(request, body, secret)
    CalSignature.verify(body, request.headers["X-Cal-Signature-256"], secret)
  end

  def self.requires_signing_secret?
    true
  end

  def self.auto_generate_signing_secret?
    true
  end

  def parse
    booking = payload["payload"] || {}

    case payload["triggerEvent"]
    when "BOOKING_CREATED"
      Result.new(title: "New booking", body: summary(booking), url: booking_url(booking))
    when "BOOKING_RESCHEDULED"
      Result.new(title: "Booking rescheduled", body: summary(booking), url: booking_url(booking))
    when "BOOKING_CANCELLED"
      Result.new(title: "Booking cancelled", body: summary(booking), url: booking_url(booking))
    when "MEETING_ENDED"
      Result.new(title: "Meeting ended", body: summary(booking), url: booking_url(booking))
    else
      Result.new(title: "Cal.com event", body: payload["triggerEvent"].to_s)
    end
  end

  private

  def summary(booking)
    name = booking.dig("attendees", 0, "name") || booking.dig("attendees", 0, "email") || "someone"
    when_text = format_time(booking["startTime"], booking.dig("attendees", 0, "timeZone"))
    [ name, when_text ].compact.join(" · ")
  end

  def format_time(iso, zone)
    return nil if iso.blank?
    time = Time.parse(iso)
    time = time.in_time_zone(zone) if zone.present?
    time.strftime("%a %b %-d, %-l:%M%P")
  rescue ArgumentError
    nil
  end

  def booking_url(booking)
    uid = booking["uid"]
    return nil if uid.blank?
    "https://app.cal.com/booking/#{uid}"
  end
end
