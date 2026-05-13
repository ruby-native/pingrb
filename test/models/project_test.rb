require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "normalizes name to stripped lowercase" do
    project = users(:one).projects.create!(name: "  Fresh Project  ")
    assert_equal "fresh project", project.name
  end

  test "name uniqueness is scoped per user and case-insensitive" do
    users(:one).projects.create!(name: "duplicates")
    dup = users(:one).projects.build(name: "Duplicates")
    assert_not dup.valid?
    assert_includes dup.errors[:name], "has already been taken"
  end

  test "different users can have projects with the same name" do
    users(:one).projects.create!(name: "shared")
    other = users(:two).projects.build(name: "shared")
    assert other.valid?
  end

  test "blank name is invalid" do
    project = users(:one).projects.build(name: "   ")
    assert_not project.valid?
    assert_includes project.errors[:name], "can't be blank"
  end
end
