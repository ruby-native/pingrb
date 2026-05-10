require "test_helper"

class GithubSignatureTest < ActiveSupport::TestCase
  SECRET = "github_test_secret"

  test "verifies a correctly signed payload" do
    body = '{"action":"opened"}'
    sig = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", SECRET, body)

    assert GithubSignature.verify(body, sig, SECRET)
  end

  test "rejects a header without the sha256= prefix" do
    body = '{"x":1}'
    bare = OpenSSL::HMAC.hexdigest("SHA256", SECRET, body)

    assert_not GithubSignature.verify(body, bare, SECRET)
  end

  test "rejects an invalid signature" do
    assert_not GithubSignature.verify('{"x":1}', "sha256=deadbeef", SECRET)
  end

  test "rejects blank header or secret" do
    assert_not GithubSignature.verify('{"x":1}', nil, SECRET)
    assert_not GithubSignature.verify('{"x":1}', "sha256=abc", "")
  end
end
