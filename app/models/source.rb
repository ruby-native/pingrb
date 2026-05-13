class Source < ApplicationRecord
  PARSER_TYPES = %w[stripe hatchbox cal status_cake github custom cli].freeze
  CREATABLE_PARSER_TYPES = PARSER_TYPES

  belongs_to :user
  belongs_to :project, optional: true
  has_many :notifications, dependent: :destroy
  has_secure_token :token, length: 32

  encrypts :signing_secret
  normalizes :signing_secret, with: ->(value) { value.presence }

  validates :name, presence: true
  validates :parser_type, inclusion: { in: PARSER_TYPES, message: "must be selected" }
  validate :new_project_name_present_when_creating

  before_validation :generate_signing_secret, on: :create
  before_validation :assign_new_project
  after_save :destroy_orphaned_previous_project
  after_destroy :destroy_orphaned_project

  attr_accessor :new_project_name

  def project_id=(value)
    if value.to_s == "new"
      @creating_new_project = true
    else
      super
    end
  end

  def parser
    "#{parser_type.classify}Parser".constantize
  end

  def display_name_for(project)
    return name unless project
    name.sub(/\A#{Regexp.escape(project.name)}\s+/i, "").presence || name
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

  def assign_new_project
    return unless @creating_new_project
    return if new_project_name.blank?
    raise "Source#assign_new_project requires a user" unless user

    self.project = user.projects.find_or_initialize_by(name: new_project_name.strip.downcase)
  end

  def new_project_name_present_when_creating
    return unless @creating_new_project
    errors.add(:new_project_name, "must be provided") if new_project_name.blank?
  end

  def destroy_orphaned_previous_project
    return unless saved_change_to_project_id?
    previous_id, _ = saved_change_to_project_id
    return unless previous_id

    previous = Project.find_by(id: previous_id)
    previous.destroy if previous && previous.sources.none?
  end

  def destroy_orphaned_project
    project.destroy if project && project.sources.none?
  end
end
