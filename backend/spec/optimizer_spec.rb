# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Retirement::Optimizer do
  it 'allocates HSA before 401k and respects match threshold' do
    paychecks = Array.new(26) { Date.new(2026, 1, 1) }
    job = {
      name: 'Primary Job',
      gross: 4000,
      paychecks: paychecks,
      hsa_allowed: 150,
      match_threshold_pct: 5,
      max_traditional_pct: 50,
      allow_roth: true,
      allow_after_tax: false,
      true_up: false
    }

    optimizer = described_class.new(jobs: [job])
    result = optimizer.optimize.first
    expect(result.contribution_input.hsa_pct).to be > 0
    expect(result.contribution_input.traditional_pct).to be >= 5
  end
end
