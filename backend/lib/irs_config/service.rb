# frozen_string_literal: true

require_relative 'validator'
require_relative 'loader'
require_relative 'errors'

module IrsConfig
  # Service class for managing IRS tax year configurations with caching
  class Service
    def initialize
      @cache = {}
      @available_years = nil
      @cache_mutex = Mutex.new
    end

    # Returns list of all available tax years
    #
    # @return [Array<Integer>] Sorted array of years
    # @raise [ConfigurationError] If no configurations are found
    def available_years
      return @available_years if @available_years

      years = Loader.discover_years

      raise ConfigurationError, "No IRS configuration files found in #{Loader::IRS_DATA_DIR}" if years.empty?

      # Filter years within valid range
      valid_years = years.select do |year|
        valid, = Validator.validate_year(year)
        warn "Skipping year #{year}: outside valid range (#{Validator::MIN_YEAR}-#{Validator::MAX_YEAR})" unless valid
        valid
      end

      raise ConfigurationError, 'No valid IRS configurations found' if valid_years.empty?

      @available_years = valid_years
    end

    # Returns the default tax year (most recent available)
    #
    # @return [Integer] The highest available year
    def default_year
      available_years.max
    end

    # Loads configuration for a specific tax year (with caching)
    #
    # @param year [Integer] The tax year
    # @return [Hash] Configuration with symbolized keys and integer values.
    #   Only keys defined in Validator::ALL_KEYS are included; extra keys in
    #   config files are ignored.
    # @raise [YearOutOfRangeError] If year is outside valid range
    # @raise [ConfigNotFoundError] If config file doesn't exist
    # @raise [ConfigurationError] If config cannot be loaded or validated
    def get_config(year)
      # Validate year
      valid, error_message = Validator.validate_year(year)
      raise YearOutOfRangeError, error_message unless valid

      # Thread-safe cache check and load
      @cache_mutex.synchronize do
        # Check cache inside mutex to prevent race conditions
        return @cache[year] if @cache.key?(year)

        # Load and validate
        config = load_and_validate(year)

        # Convert to symbolized keys with integer values
        symbolized_config = convert_to_symbolized_integers(config)

        # Cache and return
        @cache[year] = symbolized_config
        symbolized_config
      end
    end

    # Validates that at least one valid configuration exists
    # Called during application startup
    #
    # @raise [ConfigurationError] If startup validation fails
    def validate_startup!
      # Ensure at least one config exists
      available_years

      # Try to load the default year config to ensure it's valid
      default_config = get_config(default_year)

      # Verify required keys exist
      required_symbols = Validator::REQUIRED_KEYS.map { |k| k.downcase.to_sym }
      missing_keys = required_symbols - default_config.keys

      if missing_keys.any?
        raise ConfigurationError, "Default configuration missing required keys: #{missing_keys.join(', ')}"
      end

      true
    rescue Loader::LoadError => e
      raise ConfigurationError, "Startup validation failed: #{e.message}"
    end

    # Clears the configuration cache
    # Used for manual cache refresh or testing
    # Thread-safe operation
    #
    # @return [void]
    def clear_cache!
      @cache_mutex.synchronize do
        @cache.clear
        @available_years = nil
      end
    end

    private

    # Loads and validates a configuration
    #
    # @param year [Integer] The tax year
    # @return [Hash] Raw configuration with string keys and values
    # @raise [ConfigNotFoundError] If config file doesn't exist
    # @raise [ConfigurationError] If config is invalid
    def load_and_validate(year)
      config = Loader.load_config(year)

      valid, error_message = Validator.validate_config(config, year)
      raise ConfigurationError, error_message unless valid

      config
    rescue Loader::LoadError => e
      # Raise ConfigNotFoundError if the file doesn't exist
      raise ConfigNotFoundError, e.message if e.message.include?('not found')

      raise ConfigurationError, e.message
    end

    # Converts configuration from SCREAMING_SNAKE_CASE string keys to snake_case symbols with integer values
    #
    # @param config [Hash] Raw config with string keys and string values
    # @return [Hash] Processed config with symbol keys and integer values
    def convert_to_symbolized_integers(config)
      result = {}

      Validator::ALL_KEYS.each do |key|
        next unless config[key]

        symbol_key = key.downcase.to_sym
        result[symbol_key] = config[key].to_i
      end

      result
    end
  end
end
