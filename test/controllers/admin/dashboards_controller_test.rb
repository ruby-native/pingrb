require "test_helper"

module Admin
  class DashboardsControllerTest < ActionDispatch::IntegrationTest
    test "renders for an admin user" do
      sign_in_as users(:admin)
      get admin_dashboard_path
      assert_response :success
      assert_select "h2", text: /users/i
      assert_select "h2", text: /sources/i
      assert_select "h2", text: /notifications/i
      assert_select "h2", text: /devices/i
    end

    test "returns unauthorized for a non-admin user" do
      sign_in_as users(:one)
      get admin_dashboard_path
      assert_response :unauthorized
    end

    test "redirects to sign in when unauthenticated" do
      get admin_dashboard_path
      assert_redirected_to new_session_path
    end
  end
end
