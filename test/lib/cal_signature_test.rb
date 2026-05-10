require "test_helper"

class CalSignatureTest < ActiveSupport::TestCase
  SECRET = "cal_test_secret"

  test "verifies a correctly signed payload" do
    body = '{"triggerEvent":"BOOKING_CREATED"}'
    sig = OpenSSL::HMAC.hexdigest("SHA256", SECRET, body)

    assert CalSignature.verify(body, sig, SECRET)
  end

  test "rejects an invalid signature" do
    assert_not CalSignature.verify('{"x":1}', "deadbeef", SECRET)
  end

  test "rejects a blank header" do
    assert_not CalSignature.verify('{"x":1}', nil, SECRET)
    assert_not CalSignature.verify('{"x":1}', "", SECRET)
  end

  test "rejects a blank secret" do
    sig = OpenSSL::HMAC.hexdigest("SHA256", "", '{"x":1}')
    assert_not CalSignature.verify('{"x":1}', sig, "")
  end
end
