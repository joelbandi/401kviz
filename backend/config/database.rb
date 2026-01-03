require 'sequel'

# Database configuration
DB_PATH = File.expand_path('../db', __dir__)
DATABASE_URL = ENV.fetch('DATABASE_URL') do
  db_name = ENV['RACK_ENV'] == 'test' ? 'test.db' : 'development.db'
  "sqlite://#{DB_PATH}/#{db_name}"
end

# Connect to database
DB = Sequel.connect(DATABASE_URL)

# Enable better error messages
DB.extension :error_sql

# Log SQL queries in development (not in test to keep test output clean)
if ENV['RACK_ENV'] == 'development'
  require 'logger'
  DB.loggers << Logger.new($stdout)
end
