class Notification < ApplicationRecord
  belongs_to :source

  before_create { self.received_at ||= Time.current }

  broadcasts_refreshes_to ->(n) { n.source }
end
