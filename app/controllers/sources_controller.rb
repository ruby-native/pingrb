class SourcesController < ApplicationController
  before_action :set_source, only: %i[show edit update destroy rotate regenerate_signing_secret]
  before_action :set_projects, only: %i[new create edit update]

  def index
    @sources = Current.user.sources.includes(:project).order(:name)
    @notification_counts = Notification.where(source_id: @sources).group(:source_id).count
    @grouped_sources = group_sources(@sources)
  end

  def show
    @notifications = @source.notifications.order(received_at: :desc).limit(50)
  end

  def new
    @source = Current.user.sources.new(new_source_defaults)
  end

  def create
    @source = Current.user.sources.new(source_params)
    if @source.save
      redirect_to @source, notice: "Source created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @source.update(source_params)
      redirect_to @source, notice: "Saved."
    else
      render :edit, status: :unprocessable_entity
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

  def regenerate_signing_secret
    @source.regenerate_signing_secret
    redirect_to @source, notice: "Signing secret regenerated. Update #{@source.parser_type.titleize} with the new secret."
  end

  private

  def group_sources(sources)
    by_project = sources.group_by(&:project)
    named = by_project.except(nil).sort_by { |project, _| project.name }.map do |project, project_sources|
      { group: project.name, project: project, sources: project_sources }
    end
    defaults = by_project[nil].present? ? [ { group: "default", project: nil, sources: by_project[nil] } ] : []
    named + defaults
  end

  def set_source
    @source = Current.user.sources.find(params[:id])
  end

  def set_projects
    @projects = Current.user.projects.order(:name)
  end

  def new_source_defaults
    params.fetch(:source, {}).permit(:project_id)
  end

  def source_params
    params.expect(source: [ :name, :parser_type, :signing_secret, :project_id, :new_project_name ])
  end
end
