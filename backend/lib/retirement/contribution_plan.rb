# frozen_string_literal: true

module Retirement
  ContributionInput = Struct.new(
    :traditional_pct,
    :roth_pct,
    :after_tax_pct,
    :hsa_pct,
    keyword_init: true
  )

  PaycheckResult = Struct.new(
    :date,
    :gross,
    :employee_traditional,
    :employee_roth,
    :employee_after_tax,
    :employee_hsa,
    :employer_match,
    :employer_hsa,
    :federal_tax,
    :state_tax,
    :net_cash,
    :ytd_employee_401k,
    :ytd_hsa,
    :ytd_match,
    keyword_init: true
  )

  class ContributionPlan
    def initialize(gross:, contribution_input:, employer_match_rate:, employer_match_cap:, employer_hsa: 0)
      @gross = gross
      @input = contribution_input
      @employer_match_rate = employer_match_rate
      @employer_match_cap = employer_match_cap
      @employer_hsa = employer_hsa
    end

    def process_paychecks(dates)
      ytd_401k = 0
      ytd_hsa = 0
      ytd_match = 0
      dates.map do |date|
        trad = pct(@input.traditional_pct) * @gross
        roth = pct(@input.roth_pct) * @gross
        after_tax = pct(@input.after_tax_pct) * @gross
        hsa = pct(@input.hsa_pct) * @gross

        matchable = [trad + roth, @gross * @employer_match_cap].min
        employer_match = matchable * @employer_match_rate

        ytd_401k += trad + roth + after_tax
        ytd_hsa += hsa + @employer_hsa
        ytd_match += employer_match

        taxable_wages = @gross - trad - hsa
        annualized = taxable_wages * (26)
        fed_tax_annual = Constants.progressive_tax([annualized - Constants::FEDERAL_STANDARD_DEDUCTION, 0].max, Constants::FEDERAL_BRACKETS)
        ca_tax_annual = Constants.progressive_tax([annualized - Constants::CA_STANDARD_DEDUCTION, 0].max, Constants::CA_BRACKETS)
        federal_tax = fed_tax_annual / 26.0
        state_tax = ca_tax_annual / 26.0

        net_cash = @gross - trad - roth - after_tax - hsa - federal_tax - state_tax

        PaycheckResult.new(
          date: date,
          gross: @gross,
          employee_traditional: trad,
          employee_roth: roth,
          employee_after_tax: after_tax,
          employee_hsa: hsa,
          employer_match: employer_match,
          employer_hsa: @employer_hsa,
          federal_tax: federal_tax,
          state_tax: state_tax,
          net_cash: net_cash,
          ytd_employee_401k: ytd_401k,
          ytd_hsa: ytd_hsa,
          ytd_match: ytd_match
        )
      end
    end

    private

    def pct(value)
      return 0 unless value
      value.to_f / 100.0
    end
  end
end
