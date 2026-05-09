require "test_helper"

class StripeSignatureTest < ActiveSupport::TestCase
  setup do
    @secret = "whsec_test_abc123"
    @body = '{"type":"payment_intent.succeeded"}'
    @timestamp = Time.current.to_i
    @signature = OpenSSL::HMAC.hexdigest("SHA256", @secret, "#{@timestamp}.#{@body}")
    @header = "t=#{@timestamp},v1=#{@signature}"
  end

  test "passes for a valid signature" do
    assert StripeSignature.verify(@body, @header, @secret)
  end

  test "fails for a tampered body" do
    refute StripeSignature.verify("#{@body}tampered", @header, @secret)
  end

  test "fails for a wrong secret" do
    refute StripeSignature.verify(@body, @header, "whsec_wrong")
  end

  test "fails for a stale timestamp outside tolerance" do
    stale_ts = @timestamp - (10 * 60)
    stale_sig = OpenSSL::HMAC.hexdigest("SHA256", @secret, "#{stale_ts}.#{@body}")
    refute StripeSignature.verify(@body, "t=#{stale_ts},v1=#{stale_sig}", @secret)
  end

  test "fails when header is missing" do
    refute StripeSignature.verify(@body, nil, @secret)
  end

  test "fails when secret is missing" do
    refute StripeSignature.verify(@body, @header, nil)
  end

  test "fails when v1 part is missing" do
    refute StripeSignature.verify(@body, "t=#{@timestamp}", @secret)
  end
end
