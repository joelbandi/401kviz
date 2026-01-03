# frozen_string_literal: true

module IrsConfig
  # Validates IRS configuration data for year range, required keys, and value types
  class Validator
    # Required configuration keys that must be present in every .env file
    REQUIRED_KEYS = %w[
      EMPLOYEE_DEFERRAL_LIMIT
      TOTAL_401K_LIMIT
      CATCH_UP_CONTRIBUTION
    ].freeze

    # Optional configuration keys (HSA limits for future features)
    OPTIONAL_KEYS = %w[
      HSA_INDIVIDUAL_LIMIT
      HSA_FAMILY_LIMIT
    ].freeze

    # All valid keys (required + optional)
    ALL_KEYS = (REQUIRED_KEYS + OPTIONAL_KEYS).freeze

    # Valid year range for tax configurations
    MIN_YEAR = 2020
    MAX_YEAR = 2050

    # Validates that a year is within acceptable range
    #
    # @param year [Integer] The tax year to validate
    # @return [Array<Boolean, String>] [valid?, error_message]
    def self.validate_year(year)
      return [false, "Year must be an integer, got #{year.class}"] unless year.is_a?(Integer)

      unless year.between?(MIN_YEAR, MAX_YEAR)
        return [false, "Year #{year} is outside valid range (#{MIN_YEAR}-#{MAX_YEAR})"]
      end

      [true, nil]
    end

    # Validates that a configuration hash has all required keys and valid values
    #
    # @param config [Hash] Configuration hash with string keys
    # @param year [Integer] The tax year (for error messages)
    # @return [Array<Boolean, String>] [valid?, error_message]
    def self.validate_config(config, year)
      # Check required keys
      missing_keys = REQUIRED_KEYS - config.keys
      return [false, "Missing required keys for year #{year}: #{missing_keys.join(', ')}"] if missing_keys.any?

      # Validate value types and ranges
      ALL_KEYS.each do |key|
        next unless config[key]

        value = config[key]

        # Check if value is numeric string
        unless value.match?(/^\d+$/)
          return [false, "Invalid value for #{key} in year #{year}: '#{value}' is not a positive integer"]
        end

        # Check if value is positive
        return [false, "Invalid value for #{key} in year #{year}: must be greater than 0"] if value.to_i <= 0
      end

      [true, nil]
    end
  end
end
