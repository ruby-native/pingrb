module ApplicationHelper
  def public_webhook_url(parser_type:, token:)
    host_file = Rails.root.join("tmp/public_host")
    if host_file.exist? && (host = host_file.read.strip).present?
      "#{host}/webhooks/#{parser_type}/#{token}"
    else
      webhook_url(parser_type: parser_type, token: token)
    end
  end

  def hatchbox_failed_deploy_script(source)
    url = public_webhook_url(parser_type: source.parser_type, token: source.token)
    %(curl -fsS -X POST "#{url}" -d "branch=$BRANCH&revision=$REVISION&log_id=$LOG_ID")
  end
end
