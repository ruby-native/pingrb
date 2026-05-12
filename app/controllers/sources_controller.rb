class SourcesController < ApplicationController
  before_action :set_source, only: %i[show update destroy rotate]

  def index
    @sources = Current.user.sources.order(created_at: :desc)
    @notification_counts = Notification.where(source_id: @sources).group(:source_id).count
  end

  def show
    @notifications = @source.notifications.order(received_at: :desc).limit(50)
  end

  def new
    @source = Current.user.sources.new
  end

  def create
    @source = Current.user.sources.new(source_params)
    if @source.save
      redirect_to @source, notice: "Source created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @source.update(source_params)
      redirect_to @source, notice: "Saved."
    else
      redirect_to @source, alert: @source.errors.full_messages.to_sentence
    end
  end

  def destroy
    @source.destroy
    redirect_to sources_path, notice: "Source removed.", status: :see_other
  end

  def rotate
    @source.regenerate_token
    redirect_to @source, notice: "Webhook URL rotated. Update the source with the new URL."
  end

  private

  def set_source
    @source = Current.user.sources.find(params[:id])
  end

  def source_params
    params.expect(source: [ :name, :parser_type, :signing_secret ])
  end
end
