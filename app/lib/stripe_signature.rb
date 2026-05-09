class StripeSignature
  TOLERANCE_SECONDS = 5 * 60

  def self.verify(payload, header, secret)
    return false if header.blank? || secret.blank?

    parts = header.split(",").map { |s| s.split("=", 2) }.to_h
    timestamp = parts["t"].to_i
    signature = parts["v1"]
    return false if timestamp.zero? || signature.blank?
    return false if (Time.current.to_i - timestamp).abs > TOLERANCE_SECONDS

    expected = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{payload}")
    ActiveSupport::SecurityUtils.secure_compare(expected, signature)
  end
end
