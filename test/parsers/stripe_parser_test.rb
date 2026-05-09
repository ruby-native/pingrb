require "test_helper"

class StripeParserTest < ActiveSupport::TestCase
  test "parses payment_intent.succeeded" do
    result = StripeParser.parse(
      "type" => "payment_intent.succeeded",
      "data" => {
        "object" => {
          "id" => "pi_123",
          "amount" => 4999,
          "currency" => "usd",
          "receipt_email" => "joe@example.com"
        }
      }
    )

    assert_equal "New payment", result.title
    assert_equal "$49.99 USD from joe@example.com", result.body
    assert_equal "https://dashboard.stripe.com/payments/pi_123", result.url
  end

  test "parses charge.succeeded with billing_details fallback" do
    result = StripeParser.parse(
      "type" => "charge.succeeded",
      "data" => {
        "object" => {
          "id" => "ch_456",
          "amount" => 1000,
          "currency" => "usd",
          "billing_details" => { "email" => "from-billing@example.com" }
        }
      }
    )

    assert_equal "$10.00 USD from from-billing@example.com", result.body
  end

  test "parses payment_intent.payment_failed" do
    result = StripeParser.parse(
      "type" => "payment_intent.payment_failed",
      "data" => {
        "object" => { "id" => "pi_failed", "amount" => 2500, "currency" => "usd", "receipt_email" => "fail@example.com" }
      }
    )

    assert_equal "Payment failed", result.title
    assert_equal "$25.00 USD from fail@example.com", result.body
  end

  test "parses invoice.paid" do
    result = StripeParser.parse(
      "type" => "invoice.paid",
      "data" => {
        "object" => { "id" => "in_123", "amount_paid" => 9900, "currency" => "usd", "customer_email" => "sub@example.com" }
      }
    )

    assert_equal "Invoice paid", result.title
    assert_equal "$99.00 USD from sub@example.com", result.body
    assert_equal "https://dashboard.stripe.com/invoices/in_123", result.url
  end

  test "parses invoice.payment_failed" do
    result = StripeParser.parse(
      "type" => "invoice.payment_failed",
      "data" => {
        "object" => { "id" => "in_456", "amount_due" => 1900, "currency" => "usd", "customer_email" => "dunning@example.com" }
      }
    )

    assert_equal "Invoice failed", result.title
    assert_equal "$19.00 USD from dunning@example.com", result.body
  end

  test "parses charge.refunded" do
    result = StripeParser.parse(
      "type" => "charge.refunded",
      "data" => {
        "object" => { "id" => "ch_789", "amount_refunded" => 5000, "currency" => "usd", "billing_details" => { "email" => "refund@example.com" } }
      }
    )

    assert_equal "Refund issued", result.title
    assert_equal "$50.00 USD to refund@example.com", result.body
  end

  test "parses charge.dispute.created" do
    result = StripeParser.parse(
      "type" => "charge.dispute.created",
      "data" => { "object" => { "id" => "dp_789", "amount" => 2500, "currency" => "usd" } }
    )

    assert_equal "Dispute opened", result.title
    assert_equal "$25.00 USD disputed", result.body
    assert_equal "https://dashboard.stripe.com/disputes/dp_789", result.url
  end

  test "parses customer.subscription.created with price nickname" do
    result = StripeParser.parse(
      "type" => "customer.subscription.created",
      "data" => {
        "object" => {
          "id" => "sub_111",
          "items" => { "data" => [ { "price" => { "nickname" => "Pro monthly" } } ] }
        }
      }
    )

    assert_equal "New subscription", result.title
    assert_equal "Pro monthly", result.body
  end

  test "parses customer.subscription.deleted" do
    result = StripeParser.parse(
      "type" => "customer.subscription.deleted",
      "data" => {
        "object" => { "id" => "sub_222", "items" => { "data" => [ { "price" => { "nickname" => "Starter annual" } } ] } }
      }
    )

    assert_equal "Subscription cancelled", result.title
    assert_equal "Starter annual", result.body
  end

  test "falls back to event type for unknown events" do
    result = StripeParser.parse("type" => "balance.available")

    assert_equal "Stripe event", result.title
    assert_equal "balance.available", result.body
  end
end
