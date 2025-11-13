require 'net/http'
require 'json'

class AuditService
  AUDIT_SERVICE_URL = ENV.fetch('AUDIT_SERVICE_URL', 'http://localhost:3002')

  def self.log_event(resource_type:, resource_id:, action:, changes_made: {}, status:, error_message: nil)
    uri = URI("#{AUDIT_SERVICE_URL}/api/v1/auditoria")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 5
    http.open_timeout = 5
    
    request = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'application/json' })
    request.body = {
      audit_log: {
        resource_type: resource_type,
        resource_id: resource_id.to_s,
        action: action,
        changes_made: changes_made,
        status: status,
        error_message: error_message
      }
    }.to_json

    begin
      response = http.request(request)
      Rails.logger.info("Audit log created: #{response.body}")
    rescue StandardError => e
      Rails.logger.error("Failed to create audit log: #{e.message}")
    end
  end

  def self.log_create(resource_type, resource_id, changes_made = {})
    log_event(
      resource_type: resource_type,
      resource_id: resource_id,
      action: 'create',
      changes_made: changes_made,
      status: 'success'
    )
  end

  def self.log_read(resource_type, resource_id)
    log_event(
      resource_type: resource_type,
      resource_id: resource_id,
      action: 'read',
      status: 'success'
    )
  end

  def self.log_error(resource_type, resource_id, error_message, action = 'error')
    log_event(
      resource_type: resource_type,
      resource_id: resource_id,
      action: action,
      status: 'failed',
      error_message: error_message
    )
  end
end

