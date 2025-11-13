class AuditPublisherService
  class << self
    def publish(resource_type:, resource_id:, action:, changes_made: {}, status: 'success', error_message: nil)
      return unless should_publish?

      audit_data = {
        resource_type: resource_type,
        resource_id: resource_id.to_s,
        action: action,
        changes_made: changes_made,
        status: status,
        error_message: error_message,
        timestamp: Time.current.iso8601
      }

      routing_key = "audit.#{resource_type}.#{action}"

      begin
        exchange = RabbitMQConnection.exchange
        exchange.publish(
          audit_data.to_json,
          routing_key: routing_key,
          persistent: true,
          content_type: 'application/json',
          timestamp: Time.current.to_i
        )

        Rails.logger.info "Published audit event: #{routing_key} for #{resource_type}##{resource_id}"
        true
      rescue StandardError => e
        Rails.logger.error "Failed to publish audit event: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        false
      end
    end

    def publish_create(resource)
      publish(
        resource_type: resource.class.name.downcase,
        resource_id: resource.id,
        action: 'create',
        changes_made: resource.attributes,
        status: 'success'
      )
    end

    def publish_update(resource, changes)
      publish(
        resource_type: resource.class.name.downcase,
        resource_id: resource.id,
        action: 'update',
        changes_made: changes,
        status: 'success'
      )
    end

    def publish_delete(resource)
      publish(
        resource_type: resource.class.name.downcase,
        resource_id: resource.id,
        action: 'delete',
        changes_made: resource.attributes,
        status: 'success'
      )
    end

    def publish_error(resource_type:, resource_id:, action:, error_message:)
      publish(
        resource_type: resource_type,
        resource_id: resource_id,
        action: 'error',
        status: 'failed',
        error_message: error_message
      )
    end

    private

    def should_publish?
      # No publicar en entorno de test a menos que se especifique
      return false if Rails.env.test? && !ENV['AUDIT_IN_TEST']
      
      # Verificar que RabbitMQ esté conectado
      RabbitMQConnection.connection&.open? rescue false
    end
  end
end

