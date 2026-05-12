require "test_helper"

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  def stripe_signature_header(body, secret, timestamp: Time.current.to_i)
    sig = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{body}")
    "t=#{timestamp},v1=#{sig}"
  end

  test "creates a notification from a verified Stripe webhook" do
    source = sources(:stripe)
    payload = {
      "type" => "payment_intent.succeeded",
      "data" => {
        "object" => {
          "id" => "pi_123",
          "amount" => 4999,
          "currency" => "usd",
          "receipt_email" => "joe@example.com"
        }
      }
    }
    body = payload.to_json

    assert_difference -> { source.notifications.count }, 1 do
      post webhook_url(parser_type: "stripe", token: source.token),
        params: body,
        headers: {
          "Content-Type" => "application/json",
          "Stripe-Signature" => stripe_signature_header(body, source.signing_secret)
        }
    end

    assert_response :success
    notification = source.notifications.last
    assert_equal "New payment", notification.title
    assert_equal "$49.99 USD from joe@example.com", notification.body
  end

  test "rejects a Stripe webhook with an invalid signature" do
    source = sources(:stripe)
    body = '{"type":"payment_intent.succeeded"}'

    assert_no_difference -> { source.notifications.count } do
      post webhook_url(parser_type: "stripe", token: source.token),
        params: body,
        headers: {
          "Content-Type" => "application/json",
          "Stripe-Signature" => "t=1,v1=deadbeef"
        }
    end

    assert_response :unauthorized
  end

  test "rejects a Stripe webhook missing the signature header" do
    source = sources(:stripe)
    body = '{"type":"payment_intent.succeeded"}'

    assert_no_difference -> { source.notifications.count } do
      post webhook_url(parser_type: "stripe", token: source.token),
        params: body,
        headers: { "Content-Type" => "application/json" }
    end

    assert_response :unauthorized
  end

  def cal_signature(body, secret)
    OpenSSL::HMAC.hexdigest("SHA256", secret, body)
  end

  test "creates a notification from a verified Cal.com webhook" do
    source = sources(:cal)
    payload = {
      "triggerEvent" => "BOOKING_CREATED",
      "payload" => {
        "uid" => "abc123",
        "startTime" => "2026-08-21T12:00:00Z",
        "attendees" => [ { "name" => "Ada Lovelace", "email" => "ada@example.com", "timeZone" => "UTC" } ]
      }
    }
    body = payload.to_json

    post webhook_url(parser_type: "cal", token: source.token),
      params: body,
      headers: {
        "Content-Type" => "application/json",
        "X-Cal-Signature-256" => cal_signature(body, source.signing_secret)
      }

    assert_response :success
    assert_equal "New booking", source.notifications.last.title
  end

  test "rejects a Cal.com webhook with an invalid signature" do
    source = sources(:cal)
    body = '{"triggerEvent":"BOOKING_CREATED","payload":{}}'

    post webhook_url(parser_type: "cal", token: source.token),
      params: body,
      headers: {
        "Content-Type" => "application/json",
        "X-Cal-Signature-256" => "deadbeef"
      }

    assert_response :unauthorized
  end

  test "creates a notification from a StatusCake Down alert (form-encoded)" do
    source = sources(:status_cake)

    post webhook_url(parser_type: "status_cake", token: source.token),
      params: { Status: "Down", URL: "https://pingrb.com", Name: "pingrb.com", StatusCode: "503" }

    assert_response :success
    notification = source.notifications.last
    assert_equal "Site down", notification.title
    assert_equal "pingrb.com · https://pingrb.com · 503", notification.body
  end

  test "creates a notification from a Custom JSON webhook" do
    source = sources(:custom)
    payload = { "title" => "Job done", "body" => "backfill finished", "url" => "https://example.com/jobs/42" }

    post webhook_url(parser_type: "custom", token: source.token),
      params: payload.to_json,
      headers: { "Content-Type" => "application/json" }

    assert_response :success
    notification = source.notifications.last
    assert_equal "Job done", notification.title
    assert_equal "backfill finished", notification.body
    assert_equal "https://example.com/jobs/42", notification.url
  end

  test "creates a notification from a CLI JSON webhook" do
    source = sources(:cli)
    payload = { "title" => "deploy done", "body" => "main a1b2c3d" }

    post webhook_url(parser_type: "cli", token: source.token),
      params: payload.to_json,
      headers: { "Content-Type" => "application/json" }

    assert_response :success
    notification = source.notifications.last
    assert_equal "deploy done", notification.title
    assert_equal "main a1b2c3d", notification.body
  end

  test "creates a notification from a Hatchbox failed deploy script (form-encoded)" do
    source = sources(:hatchbox)

    post webhook_url(parser_type: "hatchbox", token: source.token),
      params: { branch: "main", revision: "a1b2c3d4e5f6", log_id: "42" }

    assert_response :success
    notification = source.notifications.last
    assert_equal "Deploy failed", notification.title
    assert_equal "main · a1b2c3d", notification.body
  end

  test "404s when the token does not match" do
    body = '{"type":"payment_intent.succeeded"}'
    post webhook_url(parser_type: "stripe", token: "wrong-token"),
      params: body,
      headers: {
        "Content-Type" => "application/json",
        "Stripe-Signature" => stripe_signature_header(body, "whsec_test_secret_abc")
      }

    assert_response :not_found
  end

  test "404s when parser_type does not match the source" do
    source = sources(:stripe)
    body = "{}"

    post webhook_url(parser_type: "cal", token: source.token),
      params: body,
      headers: { "Content-Type" => "application/json" }

    assert_response :not_found
  end
end
