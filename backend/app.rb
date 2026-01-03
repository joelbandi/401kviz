require 'sinatra/base'
require 'sinatra/json'
require 'rack/cors'
require 'rack/protection'
require 'dotenv/load'
require_relative 'config/database'
require_relative 'lib/irs_config/service'

# Load models
require_relative 'app/models/household'
require_relative 'app/models/spouse'
require_relative 'app/models/job'
require_relative 'app/models/contribution_setting'

class App < Sinatra::Base
  # CORS configuration for frontend
  use Rack::Cors do
    allow do
      origins 'localhost:5173', '127.0.0.1:5173'
      resource '*',
               headers: :any,
               methods: %i[get post put patch delete options]
    end
  end

  # Security middleware (disabled in test for simplicity)
  unless ENV['RACK_ENV'] == 'test'
    use Rack::Protection, except: [:json_csrf]
    use Rack::Protection::JsonCsrf
  end

  # Request size limits (10MB)
  use Rack::ContentLength
  MAX_REQUEST_SIZE = 10 * 1024 * 1024

  before do
    if request.content_length && request.content_length.to_i > MAX_REQUEST_SIZE
      halt 413, json(error: 'Request entity too large')
    end
  end

  # Configuration
  configure do
    set :show_exceptions, :after_handler
    set :dump_errors, ENV['RACK_ENV'] == 'test'

    # Initialize IRS configuration service
    irs_service = IrsConfig::Service.new

    begin
      irs_service.validate_startup!
      set :irs_config_service, irs_service

      puts "✓ IRS configuration loaded for years: #{irs_service.available_years.join(', ')}"
      puts "✓ Default year: #{irs_service.default_year}"
    rescue IrsConfig::Service::ConfigurationError => e
      warn "FATAL: Failed to load IRS configurations: #{e.message}"
      exit 1
    end
  end

  # Helper methods
  helpers do
    def irs_config_service
      settings.irs_config_service
    end

    # Parse JSON body with error handling
    def parse_json_body
      request.body.rewind
      body = request.body.read
      halt 400, json(error: 'Request body is empty') if body.empty?

      JSON.parse(body)
    rescue JSON::ParserError => e
      halt 400, json(error: "Invalid JSON: #{e.message}")
    end
  end

  # Health check endpoint
  get '/health' do
    json(
      status: 'ok',
      timestamp: Time.now.iso8601,
      version: '0.1.0'
    )
  end

  # API v1 health endpoint
  get '/api/v1/health' do
    json(
      status: 'ok',
      timestamp: Time.now.iso8601
    )
  end

  # Root endpoint
  get '/' do
    json(
      message: '401kViz API',
      version: '0.1.0',
      endpoints: {
        health: '/health',
        api: '/api/v1'
      }
    )
  end

  # Error handlers
  error 404 do
    json(error: 'Not found')
  end

  error 500 do
    json(error: 'Internal server error')
  end
end

# Load route modules
require_relative 'app/routes/config_routes'
require_relative 'app/routes/household_routes'
require_relative 'app/routes/spouse_routes'
require_relative 'app/routes/job_routes'
require_relative 'app/routes/contribution_setting_routes'
