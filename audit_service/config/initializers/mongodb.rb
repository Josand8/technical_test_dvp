# MongoDB connection configuration
require 'mongo'

Mongo::Logger.logger.level = ::Logger::INFO

# MongoDB connection configuration
MONGODB_CONFIG = {
  host: ENV.fetch("MONGODB_HOST") { "localhost" },
  port: ENV.fetch("MONGODB_PORT") { 27017 },
  database: ENV.fetch("MONGODB_DATABASE") { "audit_service_#{Rails.env}_db" },
  username: ENV.fetch("MONGODB_USERNAME") { nil },
  password: ENV.fetch("MONGODB_PASSWORD") { nil }
}

# Build connection string
connection_string = if MONGODB_CONFIG[:username] && MONGODB_CONFIG[:password]
  "mongodb://#{MONGODB_CONFIG[:username]}:#{MONGODB_CONFIG[:password]}@#{MONGODB_CONFIG[:host]}:#{MONGODB_CONFIG[:port]}/#{MONGODB_CONFIG[:database]}?authSource=admin"
else
  "mongodb://#{MONGODB_CONFIG[:host]}:#{MONGODB_CONFIG[:port]}/#{MONGODB_CONFIG[:database]}"
end

# Create MongoDB client
MONGODB_CLIENT = Mongo::Client.new(connection_string)

# Access to database
MONGODB_DB = MONGODB_CLIENT.database

