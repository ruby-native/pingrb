class Source < ApplicationRecord
  PARSER_TYPES = %w[stripe honeybadger hatchbox cal custom].freeze
  CREATABLE_PARSER_TYPES = %w[stripe hatchbox cal custom].freeze

  belongs_to :user
  has_many :notifications, dependent: :destroy
  has_secure_token :token, length: 32

  validates :name, presence: true
  validates :parser_type, inclusion: { in: PARSER_TYPES }

  def parser
    "#{parser_type.classify}Parser".constantize
  end
end
