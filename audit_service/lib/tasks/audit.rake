namespace :audit do
  desc "Start the audit consumer to process RabbitMQ messages"
  task consumer: :environment do
    Rails.logger = Logger.new($stdout)
    Rails.logger.level = Logger::INFO

    puts "Starting Audit Consumer..."
    puts "Environment: #{Rails.env}"
    puts "RabbitMQ Host: #{ENV.fetch('RABBITMQ_HOST', 'localhost')}"
    
    AuditConsumerJob.perform_now
  end
end

