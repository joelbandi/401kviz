# frozen_string_literal: true

module Retirement
  module Constants
    TAX_YEAR = 2026

    EMPLOYEE_401K_LIMIT = 23_000
    HSA_FAMILY_LIMIT = 8_300
    ANNUAL_ADDITIONS_LIMIT = 66_000

    FEDERAL_STANDARD_DEDUCTION = 30_700
    CA_STANDARD_DEDUCTION = 10_404

    FEDERAL_BRACKETS = [
      { limit: 23_200, rate: 0.10 },
      { limit: 94_300, rate: 0.12 },
      { limit: 201_050, rate: 0.22 },
      { limit: 383_900, rate: 0.24 },
      { limit: 487_450, rate: 0.32 },
      { limit: 731_200, rate: 0.35 },
      { limit: Float::INFINITY, rate: 0.37 }
    ].freeze

    CA_BRACKETS = [
      { limit: 20_659, rate: 0.01 },
      { limit: 48_435, rate: 0.02 },
      { limit: 76_215, rate: 0.04 },
      { limit: 105_387, rate: 0.06 },
      { limit: 133_667, rate: 0.08 },
      { limit: 679_015, rate: 0.093 },
      { limit: Float::INFINITY, rate: 0.103 }
    ].freeze

    def self.progressive_tax(amount, brackets)
      tax = 0
      remaining = amount
      lower_bound = 0

      brackets.each do |bracket|
        span = [bracket[:limit] - lower_bound, 0].max
        taxed = [remaining, span].min
        tax += taxed * bracket[:rate]
        remaining -= taxed
        lower_bound = bracket[:limit]
        break if remaining <= 0
      end
      tax
    end
  end
end
