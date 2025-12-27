# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Retirement::ContributionPlan do
  let(:input) do
    Retirement::ContributionInput.new(traditional_pct: 10, roth_pct: 5, after_tax_pct: 0, hsa_pct: 2)
  end

  it 'computes paycheck level values and taxes' do
    schedule = [Date.new(2026, 1, 15)]
    plan = described_class.new(gross: 4000, contribution_input: input, employer_match_rate: 0.5, employer_match_cap: 0.06, employer_hsa: 100)
    paychecks = plan.process_paychecks(schedule)
    expect(paychecks.first.employee_traditional).to eq(400)
    expect(paychecks.first.employee_roth).to eq(200)
    expect(paychecks.first.employer_match).to be_within(0.01).of(120)
    expect(paychecks.first.net_cash).to be < 4000
  end
end
