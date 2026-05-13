class Source < ApplicationRecord
  PARSER_TYPES = %w[stripe hatchbox cal status_cake custom cli].freeze
  CREATABLE_PARSER_TYPES = PARSER_TYPES

  belongs_to :user
  has_many :notifications, dependent: :destroy
  has_secure_token :token, length: 32

  encrypts :signing_secret
  normalizes :signing_secret, with: ->(value) { value.presence }

  validates :name, presence: true
  validates :parser_type, inclusion: { in: PARSER_TYPES }

  def parser
    "#{parser_type.classify}Parser".constantize
  end
end
