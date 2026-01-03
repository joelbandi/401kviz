# frozen_string_literal: true

require 'dotenv'

module IrsConfig
  # Handles file I/O and parsing of IRS configuration .env files
  class Loader
    # LoadError is raised when a configuration file cannot be loaded
    class LoadError < StandardError; end

    # Path to irs_data directory (two levels up from backend/)
    IRS_DATA_DIR = File.expand_path('../../../irs_data', __dir__)

    # Discovers all available tax years by scanning irs_data directory
    #
    # @return [Array<Integer>] Sorted array of years (e.g., [2024, 2025, 2026])
    def self.discover_years
      return [] unless Dir.exist?(IRS_DATA_DIR)

      Dir.glob(File.join(IRS_DATA_DIR, '*.env')).map do |file_path|
        File.basename(file_path, '.env').to_i
      end.select(&:positive?).sort
    end

    # Loads and parses configuration for a specific tax year
    #
    # @param year [Integer] The tax year to load
    # @return [Hash] Configuration hash with string keys and string values
    # @raise [LoadError] If file doesn't exist or cannot be parsed
    def self.load_config(year)
      file_path = File.join(IRS_DATA_DIR, "#{year}.env")

      raise LoadError, "Configuration file not found: #{file_path}" unless File.exist?(file_path)

      parse_env_file(file_path)
    rescue Errno::ENOENT => e
      raise LoadError, "Failed to read configuration file for year #{year}: #{e.message}"
    rescue StandardError => e
      raise LoadError, "Failed to parse configuration file for year #{year}: #{e.message}"
    end

    # Parses an .env file using Dotenv
    #
    # @param file_path [String] Absolute path to .env file
    # @return [Hash] Configuration hash with string keys and string values
    # @raise [LoadError] If file cannot be parsed
    private_class_method def self.parse_env_file(file_path)
      config = Dotenv.parse(file_path)

      raise LoadError, "Configuration file is empty or invalid: #{file_path}" if config.empty?

      config
    end
  end
end
