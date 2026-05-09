class WebhooksController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :verify_authenticity_token

  def create
    source = Source.find_by!(parser_type: params[:parser_type], token: params[:token])
    body = request.body.read

    return head :unauthorized unless verify_signature(source, body)

    payload = JSON.parse(body)
    result = source.parser.parse(payload)

    source.notifications.create!(
      title: result.title,
      body: result.body,
      url: result.url,
      raw_payload: body
    )

    head :ok
  rescue JSON::ParserError
    head :bad_request
  end

  private

  def verify_signature(source, body)
    case source.parser_type
    when "stripe"
      StripeSignature.verify(body, request.headers["Stripe-Signature"], source.signing_secret)
    else
      true
    end
  end
end
