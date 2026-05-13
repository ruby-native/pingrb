require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "show requires authentication" do
    get account_path
    assert_redirected_to new_session_path
  end

  test "show renders for signed-in user" do
    sign_in_as(@user)

    get account_path

    assert_response :success
    assert_select "main", text: /#{@user.email_address}/
  end

  test "destroy deletes the user and clears the session cookie" do
    sign_in_as(@user)

    assert_difference -> { User.count }, -1 do
      delete account_path
    end

    assert_redirected_to new_session_path
    assert_empty cookies[:pingrb_session_id]
  end

  test "destroy cascades to sources, sessions, and push devices" do
    sign_in_as(@user)
    @user.sources.create!(name: "test", parser_type: "custom")
    @user.push_devices.create!(token: "abc123", platform: "apple")

    delete account_path

    assert_equal 0, Source.where(user_id: @user.id).count
    assert_equal 0, Session.where(user_id: @user.id).count
    assert_equal 0, ApplicationPushDevice.where(owner_id: @user.id, owner_type: "User").count
  end

  test "destroy requires authentication" do
    assert_no_difference -> { User.count } do
      delete account_path
    end
    assert_redirected_to new_session_path
  end
end
