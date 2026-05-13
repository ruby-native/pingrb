module Admin
  class DashboardsController < BaseController
    def show
      @users_count = User.count
      @users_with_source = User.joins(:sources).distinct.count
      @users_with_device = User.joins(:push_devices).distinct.count

      @sources_count = Source::PARSER_TYPES.index_with { 0 }.merge(Source.group(:parser_type).count)
      @sources_total = @sources_count.values.sum
      @sources_pending_setup = Source.where(signing_secret: nil)
        .where(parser_type: %w[stripe cal]).count

      @notifications_total = Notification.count
      @notifications_24h = Notification.where("received_at >= ?", 24.hours.ago).count
      @notifications_7d = Notification.where("received_at >= ?", 7.days.ago).count
      @notifications_pushed = Notification.where.not(pushed_at: nil).count

      @devices_count = ApplicationPushDevice.count
      @devices_by_platform = ApplicationPushDevice.platforms.keys.index_with { 0 }
        .merge(ApplicationPushDevice.group(:platform).count)
    end
  end
end
