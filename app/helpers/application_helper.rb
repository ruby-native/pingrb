module ApplicationHelper
  def public_webhook_url(parser_type:, token:)
    host_file = Rails.root.join("tmp/public_host")
    if host_file.exist? && (host = host_file.read.strip).present?
      "#{host}/webhooks/#{parser_type}/#{token}"
    else
      webhook_url(parser_type: parser_type, token: token)
    end
  end
end
