require "test_helper"

class SourcesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "lists the user's sources" do
    get sources_path
    assert_response :success
    assert_select "li", text: /Stripe production/
  end

  test "creates a new source" do
    assert_difference -> { Current.user.sources.count }, 1 do
      post sources_path, params: { source: { name: "GitHub repo", parser_type: "stripe" } }
    end

    source = Source.last
    assert_redirected_to source
    assert_equal "GitHub repo", source.name
    assert_predicate source.token, :present?
  end

  test "rejects invalid parser_type" do
    assert_no_difference -> { Current.user.sources.count } do
      post sources_path, params: { source: { name: "Bad", parser_type: "carrierpigeon" } }
    end

    assert_response :unprocessable_entity
  end

  test "shows webhook URL on the source page" do
    source = sources(:stripe)
    get source_path(source)
    assert_response :success
    assert_select "pre", text: /webhooks\/stripe\/#{source.token}/
  end

  test "destroys a source" do
    source = sources(:stripe)
    assert_difference -> { Current.user.sources.count }, -1 do
      delete source_path(source)
    end
    assert_redirected_to sources_path
  end

  test "renames a source" do
    source = sources(:stripe)
    patch source_path(source), params: { source: { name: "Stripe staging" } }
    assert_redirected_to source
    assert_equal "Stripe staging", source.reload.name
  end

  test "edit page shows the current name" do
    source = sources(:stripe)
    get edit_source_path(source)
    assert_response :success
    assert_select "input[name='source[name]'][value=?]", source.name
  end

  test "rotates the webhook URL token" do
    source = sources(:hatchbox)
    old_token = source.token

    post rotate_source_path(source)

    assert_redirected_to source
    assert_not_equal old_token, source.reload.token
  end

  test "404s when accessing another user's source" do
    other_source = Source.create!(user: users(:two), name: "Other", parser_type: "stripe")
    get source_path(other_source)
    assert_response :not_found
  end
end
