class AddProjectToSources < ActiveRecord::Migration[8.1]
  def change
    add_column :sources, :project, :string
  end
end
