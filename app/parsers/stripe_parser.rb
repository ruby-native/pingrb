class StripeParser < Parser
  def self.verify(request, body, secret)
    StripeSignature.verify(body, request.headers["Stripe-Signature"], secret)
  end

  def self.requires_signing_secret?
    true
  end

  def parse
    object = payload.dig("data", "object") || {}

    case payload["type"]
    when "payment_intent.succeeded", "charge.succeeded"
      Result.new(
        title: "New payment",
        body: "#{format_amount(object)} from #{customer_email(object)}",
        url: "https://dashboard.stripe.com/payments/#{object['id']}"
      )
    when "payment_intent.payment_failed", "charge.failed"
      Result.new(
        title: "Payment failed",
        body: "#{format_amount(object)} from #{customer_email(object)}",
        url: "https://dashboard.stripe.com/payments/#{object['id']}"
      )
    when "invoice.paid"
      Result.new(
        title: "Invoice paid",
        body: "#{format_amount(object, field: 'amount_paid')} from #{customer_email(object)}",
        url: "https://dashboard.stripe.com/invoices/#{object['id']}"
      )
    when "invoice.payment_failed"
      Result.new(
        title: "Invoice failed",
        body: "#{format_amount(object, field: 'amount_due')} from #{customer_email(object)}",
        url: "https://dashboard.stripe.com/invoices/#{object['id']}"
      )
    when "charge.refunded"
      refunded = object["amount_refunded"].to_i / 100.0
      Result.new(
        title: "Refund issued",
        body: "$#{format('%.2f', refunded)} #{currency(object)} to #{customer_email(object)}",
        url: "https://dashboard.stripe.com/payments/#{object['id']}"
      )
    when "charge.dispute.created"
      Result.new(
        title: "Dispute opened",
        body: "#{format_amount(object)} disputed",
        url: "https://dashboard.stripe.com/disputes/#{object['id']}"
      )
    when "customer.subscription.created"
      Result.new(
        title: "New subscription",
        body: subscription_summary(object),
        url: "https://dashboard.stripe.com/subscriptions/#{object['id']}"
      )
    when "customer.subscription.deleted"
      Result.new(
        title: "Subscription cancelled",
        body: subscription_summary(object),
        url: "https://dashboard.stripe.com/subscriptions/#{object['id']}"
      )
    else
      Result.new(title: "Stripe event", body: payload["type"].to_s)
    end
  end

  private

  def format_amount(object, field: "amount")
    amount = object[field].to_i / 100.0
    "$#{format('%.2f', amount)} #{currency(object)}"
  end

  def currency(object)
    object["currency"].to_s.upcase
  end

  def customer_email(object)
    object["receipt_email"] ||
      object["customer_email"] ||
      object.dig("billing_details", "email") ||
      object.dig("customer_details", "email") ||
      "a customer"
  end

  def subscription_summary(object)
    item = object.dig("items", "data", 0)
    nickname = item&.dig("price", "nickname") || item&.dig("plan", "nickname")
    nickname || object["customer_email"] || "subscription #{object['id']}"
  end
end
