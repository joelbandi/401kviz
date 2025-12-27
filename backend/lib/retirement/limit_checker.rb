# frozen_string_literal: true

module Retirement
  class LimitChecker
    Result = Struct.new(:within_limits, :warnings, keyword_init: true)

    def initialize(paychecks)
      @paychecks = paychecks
    end

    def validate
      warnings = []
      employee_total = @paychecks.sum { |p| p.employee_traditional + p.employee_roth }
      hsa_total = @paychecks.sum { |p| p.employee_hsa + p.employer_hsa }
      additions_total = @paychecks.sum do |p|
        p.employee_traditional + p.employee_roth + p.employee_after_tax + p.employer_match
      end

      if employee_total > Constants::EMPLOYEE_401K_LIMIT
        warnings << "Employee 401(k) limit exceeded by $#{(employee_total - Constants::EMPLOYEE_401K_LIMIT).round(2)}"
      end

      if hsa_total > Constants::HSA_FAMILY_LIMIT
        warnings << "HSA family limit exceeded by $#{(hsa_total - Constants::HSA_FAMILY_LIMIT).round(2)}"
      end

      if additions_total > Constants::ANNUAL_ADDITIONS_LIMIT
        warnings << "Annual additions limit exceeded by $#{(additions_total - Constants::ANNUAL_ADDITIONS_LIMIT).round(2)}"
      end

      Result.new(within_limits: warnings.empty?, warnings: warnings)
    end
  end
end
