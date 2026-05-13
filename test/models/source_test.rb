require "test_helper"

class SourceTest < ActiveSupport::TestCase
  test "auto-generates a signing secret for Cal sources on create" do
    source = users(:one).sources.create!(name: "Cal", parser_type: "cal")
    assert_predicate source.signing_secret, :present?
    assert_equal 64, source.signing_secret.length
  end

  test "auto-generates a signing secret for GitHub sources on create" do
    source = users(:one).sources.create!(name: "Repo", parser_type: "github")
    assert_predicate source.signing_secret, :present?
  end

  test "does not auto-generate a signing secret for Stripe sources" do
    source = users(:one).sources.create!(name: "Stripe", parser_type: "stripe")
    assert_nil source.signing_secret
  end

  test "does not auto-generate a signing secret for token-only parsers" do
    %w[hatchbox status_cake custom cli].each do |parser_type|
      source = users(:one).sources.create!(name: parser_type, parser_type: parser_type)
      assert_nil source.signing_secret, "expected #{parser_type} to skip auto-gen"
    end
  end

  test "does not overwrite a user-supplied signing secret on create" do
    source = users(:one).sources.create!(name: "Cal", parser_type: "cal", signing_secret: "my-own-secret")
    assert_equal "my-own-secret", source.signing_secret
  end

  test "regenerate_signing_secret replaces the existing value" do
    source = users(:one).sources.create!(name: "Cal", parser_type: "cal")
    original = source.signing_secret

    source.regenerate_signing_secret

    assert_not_equal original, source.signing_secret
    assert_predicate source.signing_secret, :present?
  end

  test "requires new_project_name when project_id is the 'new' sentinel" do
    source = users(:one).sources.build(name: "x", parser_type: "custom", project_id: "new")
    assert_not source.valid?
    assert_includes source.errors[:new_project_name], "must be provided"
  end

  test "creates a new project when project_id is 'new' and a name is provided" do
    assert_difference "Project.count", 1 do
      source = users(:one).sources.create!(name: "x", parser_type: "custom", project_id: "new", new_project_name: "fresh")
      assert_equal "fresh", source.project.name
    end
  end

  test "reuses an existing project when new_project_name matches case-insensitively" do
    project = users(:one).projects.create!(name: "shared")
    assert_no_difference "Project.count" do
      source = users(:one).sources.create!(name: "x", parser_type: "custom", project_id: "new", new_project_name: "Shared")
      assert_equal project.id, source.project_id
    end
  end

  test "blank project_id assigns no project" do
    source = users(:one).sources.create!(name: "x", parser_type: "custom", project_id: "")
    assert_nil source.project
  end

  test "destroys orphan project when last source moves out" do
    project = users(:one).projects.create!(name: "lonely-move")
    source = users(:one).sources.create!(name: "x", parser_type: "custom", project: project)

    source.update!(project: nil)

    assert_not Project.exists?(project.id)
  end

  test "destroys orphan project when last source is deleted" do
    project = users(:one).projects.create!(name: "lonely-delete")
    source = users(:one).sources.create!(name: "x", parser_type: "custom", project: project)

    source.destroy

    assert_not Project.exists?(project.id)
  end

  test "leaves project intact when other sources remain" do
    project = users(:one).projects.create!(name: "kept")
    keeper = users(:one).sources.create!(name: "keeper", parser_type: "custom", project: project)
    leaver = users(:one).sources.create!(name: "leaver", parser_type: "custom", project: project)

    leaver.destroy

    assert Project.exists?(project.id)
    assert_equal [ keeper.id ], project.reload.sources.pluck(:id)
  end

end
