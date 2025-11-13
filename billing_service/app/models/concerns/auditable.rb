module Auditable
  extend ActiveSupport::Concern

  included do
    after_create :audit_create
    after_update :audit_update
    after_destroy :audit_destroy
    after_rollback :audit_error_on_rollback
  end

  private

  def audit_create
    AuditPublisherService.publish_create(self)
  rescue StandardError => e
    Rails.logger.error "Failed to audit create for #{self.class.name}##{id}: #{e.message}"
  end

  def audit_update
    return unless saved_changes?

    changes_to_audit = saved_changes.except('updated_at', 'created_at')
    return if changes_to_audit.empty?

    AuditPublisherService.publish_update(self, changes_to_audit)
  rescue StandardError => e
    Rails.logger.error "Failed to audit update for #{self.class.name}##{id}: #{e.message}"
  end

  def audit_destroy
    AuditPublisherService.publish_delete(self)
  rescue StandardError => e
    Rails.logger.error "Failed to audit destroy for #{self.class.name}##{id}: #{e.message}"
  end

  def audit_error_on_rollback
    return unless errors.any?

    AuditPublisherService.publish_error(
      resource_type: self.class.name.downcase,
      resource_id: id || 'unknown',
      action: 'error',
      error_message: errors.full_messages.join(', ')
    )
  rescue StandardError => e
    Rails.logger.error "Failed to audit error for #{self.class.name}: #{e.message}"
  end
end

