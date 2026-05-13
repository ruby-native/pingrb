class GithubSignature
  def self.verify(payload, header, secret)
    return false if header.blank? || secret.blank?
    return false unless header.start_with?("sha256=")

    expected = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", secret, payload)
    ActiveSupport::SecurityUtils.secure_compare(expected, header)
  end
end
