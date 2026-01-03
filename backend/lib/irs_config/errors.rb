# frozen_string_literal: true

module IrsConfig
  # Base error class for IRS configuration errors
  class ConfigurationError < StandardError
    attr_reader :status_code

    def initialize(message, status_code: 500)
      super(message)
      @status_code = status_code
    end
  end

  # Raised when a requested year is outside the valid range (2020-2050)
  class YearOutOfRangeError < ConfigurationError
    def initialize(message)
      super(message, status_code: 400)
    end
  end

  # Raised when a configuration file is not found for a given year
  class ConfigNotFoundError < ConfigurationError
    def initialize(message)
      super(message, status_code: 404)
    end
  end

  # Raised when a year parameter is invalid (not numeric)
  class InvalidYearParameterError < ConfigurationError
    def initialize(message)
      super(message, status_code: 400)
    end
  end
end
