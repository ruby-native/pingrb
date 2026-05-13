require "test_helper"

class GithubSignatureTest < ActiveSupport::TestCase
  SECRET = "github_test_secret"

  test "verifies a correctly signed payload" do
    body = '{"action":"opened"}'
    header = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", SECRET, body)

    assert GithubSignature.verify(body, header, SECRET)
  end

  test "rejects an invalid signature" do
    assert_not GithubSignature.verify('{"x":1}', "sha256=deadbeef", SECRET)
  end

  test "rejects a header missing the sha256= prefix" do
    body = '{"x":1}'
    digest = OpenSSL::HMAC.hexdigest("SHA256", SECRET, body)

    assert_not GithubSignature.verify(body, digest, SECRET)
  end

  test "rejects a blank header" do
    assert_not GithubSignature.verify('{"x":1}', nil, SECRET)
    assert_not GithubSignature.verify('{"x":1}', "", SECRET)
  end

  test "rejects a blank secret" do
    body = '{"x":1}'
    header = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", "", body)

    assert_not GithubSignature.verify(body, header, "")
  end
end
