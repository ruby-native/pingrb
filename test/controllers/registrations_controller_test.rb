require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "renders the sign up form" do
    get new_registration_path
    assert_response :success
    assert_select "form"
  end

  test "creates a user and signs them in" do
    assert_difference -> { User.count }, 1 do
      post registration_path, params: {
        user: { email_address: "new@example.com", password: "secret123", password_confirmation: "secret123" }
      }
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_redirected_to sources_path
    follow_redirect!
    assert_response :success
  end

  test "rejects mismatched password confirmation" do
    assert_no_difference -> { User.count } do
      post registration_path, params: {
        user: { email_address: "fail@example.com", password: "a", password_confirmation: "b" }
      }
    end

    assert_response :unprocessable_entity
  end
end
