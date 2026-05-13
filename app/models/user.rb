class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :sources, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :push_devices, class_name: "ApplicationPushDevice", as: :owner, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
