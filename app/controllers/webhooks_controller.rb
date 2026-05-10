class WebhooksController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :verify_authenticity_token

  def create
    source = Source.find_by!(parser_type: params[:parser_type], token: params[:token])
    body = request.body.read

    return head :unauthorized unless source.parser.verify(request, body, source.signing_secret)

    payload = parse_body(body)
    result = source.parser.parse(payload, request: request)

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

  def parse_body(body)
    if request.media_type == "application/x-www-form-urlencoded"
      Rack::Utils.parse_nested_query(body)
    else
      JSON.parse(body)
    end
  end
end
