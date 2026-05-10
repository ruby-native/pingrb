class CalSignature
  def self.verify(payload, header, secret)
    return false if header.blank? || secret.blank?

    expected = OpenSSL::HMAC.hexdigest("SHA256", secret, payload)
    ActiveSupport::SecurityUtils.secure_compare(expected, header)
  end
end
