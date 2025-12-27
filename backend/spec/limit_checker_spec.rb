# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Retirement::LimitChecker do
  it 'flags limits exceeded' do
    paycheck = Retirement::PaycheckResult.new(
      date: Date.new(2026, 1, 15),
      gross: 4000,
      employee_traditional: 20_000,
      employee_roth: 5_000,
      employee_after_tax: 2_000,
      employee_hsa: 4_000,
      employer_match: 10_000,
      employer_hsa: 500,
      federal_tax: 0,
      state_tax: 0,
      net_cash: 0,
      ytd_employee_401k: 0,
      ytd_hsa: 0,
      ytd_match: 0
    )

    result = described_class.new([paycheck]).validate
    expect(result.warnings).not_to be_empty
    expect(result.within_limits).to be(false)
  end
end
