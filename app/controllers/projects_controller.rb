class ProjectsController < ApplicationController
  before_action :set_project

  def show
    @sources = @project.sources.order(created_at: :desc)
    @notification_counts = Notification.where(source_id: @sources).group(:source_id).count
  end

  def edit
  end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: "Project saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to sources_path, notice: "Project removed. Sources moved to default.", status: :see_other
  end

  private

  def set_project
    @project = Current.user.projects.find(params[:id])
  end

  def project_params
    params.expect(project: [ :name ])
  end
end
