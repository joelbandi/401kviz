# frozen_string_literal: true

require 'date'

module Retirement
  class PaycheckSchedule
    FREQUENCIES = {
      weekly: 7,
      biweekly: 14,
      semimonthly: 15,
      monthly: 30
    }.freeze

    def initialize(first_paycheck_date:, frequency: nil, paycheck_count: nil)
      @first_paycheck_date = Date.parse(first_paycheck_date.to_s)
      @frequency = frequency&.to_sym
      @paycheck_count = paycheck_count
      validate!
    end

    def dates_for_year(year = Constants::TAX_YEAR)
      dates = []
      current = @first_paycheck_date
      while current.year == year && (!@paycheck_count || dates.size < @paycheck_count)
        dates << current
        break unless increment
        current += increment
      end
      dates
    end

    private

    def increment
      return nil if @paycheck_count && dates_exhausted?
      return FREQUENCIES[@frequency] if @frequency
      return 0 if @paycheck_count

      raise ArgumentError, 'Either frequency or paycheck_count required'
    end

    def dates_exhausted?
      false
    end

    def validate!
      raise ArgumentError, 'first paycheck date required' unless @first_paycheck_date
      raise ArgumentError, 'frequency or paycheck_count required' unless @frequency || @paycheck_count
      return unless @frequency
      raise ArgumentError, "unsupported frequency #{@frequency}" unless FREQUENCIES[@frequency]
    end
  end
end
