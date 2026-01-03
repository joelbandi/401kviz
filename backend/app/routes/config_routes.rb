# frozen_string_literal: true

# IRS Configuration API Routes
class App < Sinatra::Base
  # GET /api/v1/config/tax-years
  # Returns list of available tax years and the default year
  #
  # Response:
  # {
  #   "years": [2024, 2025, 2026],
  #   "default_year": 2026
  # }
  get '/api/v1/config/tax-years' do
    json(
      years: irs_config_service.available_years,
      default_year: irs_config_service.default_year
    )
  rescue IrsConfig::ConfigurationError => e
    halt e.status_code, json(error: e.message)
  end

  # GET /api/v1/config/tax-year/:year
  # Returns IRS configuration for a specific tax year
  #
  # Response:
  # {
  #   "year": 2026,
  #   "config": {
  #     "employee_deferral_limit": 24500,
  #     "total_401k_limit": 72000,
  #     "hsa_individual_limit": 4300,
  #     "hsa_family_limit": 8550,
  #     "catch_up_contribution": 7500
  #   }
  # }
  #
  # Error responses:
  # - 400: Invalid year (not numeric or out of range)
  # - 404: Configuration not found for year
  # - 500: Internal server error
  get '/api/v1/config/tax-year/:year' do
    year_param = params[:year]

    # Validate that the parameter is numeric
    unless year_param.match?(/^\d+$/)
      raise IrsConfig::InvalidYearParameterError, "Invalid year parameter: '#{year_param}' must be a positive integer"
    end

    year = year_param.to_i
    config = irs_config_service.get_config(year)

    json(
      year: year,
      config: config
    )
  rescue IrsConfig::ConfigurationError => e
    # Use the status code from the exception
    halt e.status_code, json(error: e.message)
  end

  # POST /api/v1/config/cache/refresh
  # Clears the configuration cache and reloads
  #
  # Response:
  # {
  #   "message": "Cache refreshed successfully",
  #   "years_loaded": [2024, 2025, 2026],
  #   "default_year": 2026
  # }
  post '/api/v1/config/cache/refresh' do
    irs_config_service.clear_cache!

    # Reload by accessing available_years
    years = irs_config_service.available_years

    json(
      message: 'Cache refreshed successfully',
      years_loaded: years,
      default_year: irs_config_service.default_year
    )
  rescue IrsConfig::ConfigurationError => e
    halt e.status_code, json(error: "Failed to refresh cache: #{e.message}")
  end
end
