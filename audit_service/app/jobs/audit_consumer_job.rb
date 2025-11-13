class AuditConsumerJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting Audit Consumer Job"

    begin
      RabbitMQConnection.connect

      queue = RabbitMQConnection.queue

      Rails.logger.info "Listening for audit events on queue: #{queue.name}"

      queue.subscribe(block: true, manual_ack: true) do |delivery_info, properties, payload|
        process_audit_event(payload, delivery_info.delivery_tag, delivery_info.routing_key)
      end
    rescue Interrupt => _
      Rails.logger.info "Audit Consumer Job interrupted"
      RabbitMQConnection.disconnect
    rescue StandardError => e
      Rails.logger.error "Audit Consumer Job error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      sleep 5
      retry
    end
  end

  private

  def process_audit_event(payload, delivery_tag, routing_key)
    Rails.logger.info "Processing audit event: #{routing_key}"

    begin
      audit_data = JSON.parse(payload)

      audit_log = AuditLog.new(
        resource_type: audit_data['resource_type'],
        resource_id: audit_data['resource_id'],
        action: audit_data['action'],
        changes_made: audit_data['changes_made'] || {},
        status: audit_data['status'],
        error_message: audit_data['error_message']
      )

      if audit_log.save
        Rails.logger.info "Audit log saved successfully: #{audit_log.id}"
        RabbitMQConnection.channel.ack(delivery_tag)
      else
        Rails.logger.error "Failed to save audit log: #{audit_log.errors.full_messages.join(', ')}"
        RabbitMQConnection.channel.nack(delivery_tag, false, true)
      end
    rescue JSON::ParserError => e
      Rails.logger.error "Invalid JSON payload: #{e.message}"
      # Rechazar el mensaje sin reencolarlo (mensaje malformado)
      RabbitMQConnection.channel.nack(delivery_tag, false, false)
    rescue StandardError => e
      Rails.logger.error "Error processing audit event: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      # Rechazar el mensaje y reencolarlo
      RabbitMQConnection.channel.nack(delivery_tag, false, true)
    end
  end
end

