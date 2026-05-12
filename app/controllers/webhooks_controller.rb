class WebhooksController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :verify_authenticity_token

  def create
    Rails.logger.tagged("webhook", params[:parser_type]) do
      source = Source.find_by(parser_type: params[:parser_type], token: params[:token])
      unless source
        Rails.logger.warn("rejected: source not found token=#{params[:token].to_s.first(8)}")
        return head :not_found
      end

      body = request.raw_post
      unless source.parser.verify(request, body, source.signing_secret)
        Rails.logger.warn("rejected: invalid signature source=#{source.id} body_bytes=#{body.bytesize}")
        return head :unauthorized
      end

      payload = begin
        parse_body(body)
      rescue JSON::ParserError => e
        Rails.logger.warn("rejected: JSON parse failed source=#{source.id} message=#{e.message}")
        return head :bad_request
      end

      result = source.parser.parse(payload)
      notification = source.notifications.create!(
        title: result.title,
        body: result.body,
        url: result.url,
        raw_payload: body
      )
      deliver_push(notification, source)
      Rails.logger.info("accepted source=#{source.id} title=#{result.title.inspect}")
      head :ok
    end
  end

  private

  def deliver_push(notification, source)
    devices = source.user.push_devices.to_a
    return if devices.empty?

    ApplicationPushNotification
      .with_data(path: source_path(source))
      .new(title: notification.title, body: notification.body)
      .deliver_later_to(devices)
  end

  def parse_body(body)
    if request.media_type == "application/x-www-form-urlencoded"
      Rack::Utils.parse_nested_query(body)
    else
      JSON.parse(body)
    end
  end
end
