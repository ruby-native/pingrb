class DevicesController < ApplicationController
  before_action :set_device, only: %i[test destroy]

  def index
    @devices = Current.user.push_devices.order(created_at: :desc)
  end

  def test
    ApplicationPushNotification
      .with_data(path: devices_path)
      .new(title: "test push", body: "hello from pingrb")
      .deliver_later_to([ @device ])

    redirect_to devices_path, notice: "Test push sent."
  end

  def destroy
    @device.destroy
    redirect_to devices_path, notice: "Device removed.", status: :see_other
  end

  private

  def set_device
    @device = Current.user.push_devices.find(params[:id])
  end
end
