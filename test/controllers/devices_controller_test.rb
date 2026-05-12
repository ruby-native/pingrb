require "test_helper"

class DevicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @device = users(:one).push_devices.create!(platform: "apple", token: "test-device-token-abc")
  end

  test "lists the user's devices" do
    get devices_path
    assert_response :success
    assert_select "li", text: /apple/i
  end

  test "shows an empty state when no devices are registered" do
    Current.user.push_devices.destroy_all
    get devices_path
    assert_response :success
    assert_select "p", text: /no devices registered/i
  end

  test "sends a test push" do
    post test_device_path(@device)
    assert_redirected_to devices_path
    follow_redirect!
    assert_match(/test push sent/i, response.body)
  end

  test "destroys a device" do
    assert_difference -> { Current.user.push_devices.count }, -1 do
      delete device_path(@device)
    end
    assert_redirected_to devices_path
  end

  test "404s when testing another user's device" do
    other_device = users(:two).push_devices.create!(platform: "apple", token: "other-device-token")
    post test_device_path(other_device)
    assert_response :not_found
  end

  test "404s when destroying another user's device" do
    other_device = users(:two).push_devices.create!(platform: "apple", token: "other-device-token-2")
    delete device_path(other_device)
    assert_response :not_found
  end
end
