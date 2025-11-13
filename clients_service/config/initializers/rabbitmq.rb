require 'bunny'

module RabbitMQConnection
  class << self
    attr_accessor :connection, :channel

    def connect
      return if @connection&.open?

      @connection = Bunny.new(
        host: ENV.fetch('RABBITMQ_HOST', 'localhost'),
        port: ENV.fetch('RABBITMQ_PORT', 5672),
        user: ENV.fetch('RABBITMQ_USER', 'guest'),
        password: ENV.fetch('RABBITMQ_PASSWORD', 'guest'),
        vhost: ENV.fetch('RABBITMQ_VHOST', '/'),
        automatically_recover: true,
        network_recovery_interval: 5
      )

      @connection.start
      @channel = @connection.create_channel

      @exchange = @channel.topic('audit_events', durable: true)

      Rails.logger.info "RabbitMQ connected successfully on #{ENV.fetch('RABBITMQ_HOST', 'localhost')}"
    rescue StandardError => e
      Rails.logger.error "Failed to connect to RabbitMQ: #{e.message}"
      @connection = nil
      @channel = nil
    end

    def disconnect
      @channel&.close
      @connection&.close
      @connection = nil
      @channel = nil
    end

    def exchange
      connect unless @channel&.open?
      @exchange
    end
  end
end

# Conectar al iniciar la aplicación
RabbitMQConnection.connect if defined?(Rails::Server)

