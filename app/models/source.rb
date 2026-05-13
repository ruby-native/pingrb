class Source < ApplicationRecord
  PARSER_TYPES = %w[stripe hatchbox cal status_cake github custom cli].freeze
  CREATABLE_PARSER_TYPES = PARSER_TYPES

  belongs_to :user
  has_many :notifications, dependent: :destroy
  has_secure_token :token, length: 32

  encrypts :signing_secret
  normalizes :signing_secret, with: ->(value) { value.presence }

  validates :name, presence: true
  validates :parser_type, inclusion: { in: PARSER_TYPES }

  before_validation :generate_signing_secret, on: :create

  def parser
    "#{parser_type.classify}Parser".constantize
  end

  def regenerate_signing_secret
    update!(signing_secret: self.class.generate_signing_secret)
  end

  def self.generate_signing_secret
    SecureRandom.hex(32)
  end

  private

  def generate_signing_secret
    return unless parser_type.in?(PARSER_TYPES)
    return unless parser.auto_generate_signing_secret?
    return if signing_secret.present?

    self.signing_secret = self.class.generate_signing_secret
  end
end
