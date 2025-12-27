# frozen_string_literal: true

module Retirement
  class Optimizer
    OptimizedJob = Struct.new(:job_name, :contribution_input, :notes, keyword_init: true)

    def initialize(jobs:, hsa_target: Constants::HSA_FAMILY_LIMIT)
      @jobs = jobs
      @hsa_target = hsa_target
    end

    def optimize
      remaining_hsa = @hsa_target
      remaining_401k = Constants::EMPLOYEE_401K_LIMIT

      @jobs.map do |job|
        paycheck_count = job[:paychecks].size
        hsa_per_check = [remaining_hsa / paycheck_count.to_f, job[:hsa_allowed]].min
        remaining_hsa -= hsa_per_check * paycheck_count

        match_threshold = job[:match_threshold_pct] || 0
        trad_pct = [match_threshold, job[:max_traditional_pct] || 100].min

        if remaining_401k.positive?
          trad_room = [remaining_401k / (paycheck_count * job[:gross]).to_f * 100, job[:max_traditional_pct] || 100].min
          trad_pct = [trad_room, trad_pct].max
          remaining_401k -= (trad_pct / 100.0) * job[:gross] * paycheck_count
        end

        Roth_pct = job[:allow_roth] ? (job[:preferred_roth_pct] || 0) : 0
        after_tax_pct = job[:allow_after_tax] ? (job[:preferred_after_tax_pct] || 0) : 0

        OptimizedJob.new(
          job_name: job[:name],
          contribution_input: ContributionInput.new(
            traditional_pct: trad_pct.round(2),
            roth_pct: Roth_pct,
            after_tax_pct: after_tax_pct,
            hsa_pct: (hsa_per_check / job[:gross] * 100).round(2)
          ),
          notes: [
            "Match threshold #{match_threshold}% applied",
            (job[:true_up] ? 'True-up allows safe front-loading' : 'Per-paycheck match preserved'),
            (job[:allow_after_tax] ? 'After-tax allowed' : 'After-tax not allowed')
          ]
        )
      end
    end
  end
end
