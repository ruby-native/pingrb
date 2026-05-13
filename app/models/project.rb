class Project < ApplicationRecord
  belongs_to :user
  has_many :sources, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }

  normalizes :name, with: ->(value) { value.to_s.strip.downcase.presence }
end
