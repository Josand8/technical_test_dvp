class AuditLog < ApplicationDocument
  include Mongoid::Document
  include Mongoid::Timestamps

  field :resource_type, type: String
  field :resource_id, type: String
  field :action, type: String
  field :changes_made, type: Hash, default: {}
  field :status, type: String
  field :error_message, type: String
  field :created_at, type: DateTime

  validates :resource_type, presence: true, inclusion: { in: %w[client invoice] }
  validates :resource_id, presence: true
  validates :action, presence: true, inclusion: { in: %w[create read update delete error] }
  validates :status, presence: true, inclusion: { in: %w[success failed] }

  before_create :set_created_at

  index({ resource_type: 1, resource_id: 1 })
  index({ resource_id: 1 })
  index({ created_at: -1 })
  index({ status: 1 })
  index({ status: 1, created_at: -1 })
  index({ resource_type: 1, status: 1, created_at: -1 })

  private

  def set_created_at
    self.created_at ||= Time.current
  end

end