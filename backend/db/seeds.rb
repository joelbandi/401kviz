# frozen_string_literal: true

require_relative '../config/database'
require_relative '../app/models/household'
require_relative '../app/models/spouse'
require_relative '../app/models/job'
require_relative '../app/models/contribution_setting'

puts 'Clearing existing data...'
ContributionSetting.truncate
Job.truncate
Spouse.truncate
Household.truncate

puts 'Creating sample household...'
household = Household.create(
  name: 'Smith Family',
  tax_year: 2026,
  filing_status: 'married_filing_jointly',
  state: 'CA',
  status: 'in_progress'
)

puts 'Creating spouses...'
spouse1 = Spouse.create(
  household_id: household.id,
  name: 'Alex Smith'
)

spouse2 = Spouse.create(
  household_id: household.id,
  name: 'Jordan Smith'
)

puts 'Creating jobs with matching and bonuses...'

# Spouse 1 - Job 1: High salary with generous match
job1 = Job.create(
  spouse_id: spouse1.id,
  employer_name: 'Tech Corp',
  first_paycheck_date: Date.new(2026, 1, 15),
  pay_frequency: 'biweekly',
  base_salary: 15_000_000, # $150,000
  bonus_amount: 2_000_000, # $20,000
  bonus_date: Date.new(2026, 12, 15),
  pretax_enabled: true,
  roth_enabled: true,
  aftertax_enabled: true,
  mega_backdoor_allowed: true,
  match_percent: 50.0, # 50% match
  match_cap_percent: 6.0, # up to 6% of salary
  true_up: true,
  starting_ytd_pretax: 0,
  starting_ytd_roth: 0,
  starting_ytd_aftertax: 0,
  starting_ytd_match: 0
)

ContributionSetting.create(
  job_id: job1.id,
  pretax_pct: 10.0,
  roth_pct: 5.0,
  aftertax_pct: 0.0
)

# Spouse 1 - Job 2: Part-time consulting (overlapping)
job2 = Job.create(
  spouse_id: spouse1.id,
  employer_name: 'Consulting LLC',
  first_paycheck_date: Date.new(2026, 6, 1),
  pay_frequency: 'monthly',
  base_salary: 3_600_000, # $36,000
  bonus_amount: 0,
  pretax_enabled: true,
  roth_enabled: true,
  aftertax_enabled: false,
  mega_backdoor_allowed: false,
  match_percent: 25.0, # 25% match
  match_cap_percent: 4.0, # up to 4% of salary
  true_up: false,
  starting_ytd_pretax: 0,
  starting_ytd_roth: 0,
  starting_ytd_aftertax: 0,
  starting_ytd_match: 0
)

ContributionSetting.create(
  job_id: job2.id,
  pretax_pct: 15.0,
  roth_pct: 0.0,
  aftertax_pct: 0.0
)

# Spouse 2 - Job 1: Mid-year start with starting YTD
job3 = Job.create(
  spouse_id: spouse2.id,
  employer_name: 'Healthcare Partners',
  first_paycheck_date: Date.new(2026, 7, 1),
  pay_frequency: 'semi_monthly',
  base_salary: 12_000_000, # $120,000
  bonus_amount: 1_500_000, # $15,000
  bonus_date: Date.new(2026, 11, 30),
  pretax_enabled: true,
  roth_enabled: true,
  aftertax_enabled: false,
  mega_backdoor_allowed: false,
  match_percent: 100.0, # 100% match (dollar for dollar)
  match_cap_percent: 5.0, # up to 5% of salary
  true_up: false,
  starting_ytd_pretax: 800_000, # $8,000 contributed at previous employer
  starting_ytd_roth: 400_000, # $4,000 contributed at previous employer
  starting_ytd_aftertax: 0,
  starting_ytd_match: 600_000 # $6,000 matched at previous employer
)

ContributionSetting.create(
  job_id: job3.id,
  pretax_pct: 8.0,
  roth_pct: 7.0,
  aftertax_pct: 0.0
)

# Spouse 2 - Job 2: Basic job with no match
job4 = Job.create(
  spouse_id: spouse2.id,
  employer_name: 'Retail Co',
  first_paycheck_date: Date.new(2026, 1, 5),
  pay_frequency: 'weekly',
  base_salary: 4_800_000, # $48,000
  bonus_amount: 0,
  pretax_enabled: true,
  roth_enabled: false,
  aftertax_enabled: false,
  mega_backdoor_allowed: false,
  match_percent: 0.0, # No match
  match_cap_percent: 0.0,
  true_up: false,
  starting_ytd_pretax: 0,
  starting_ytd_roth: 0,
  starting_ytd_aftertax: 0,
  starting_ytd_match: 0
)

ContributionSetting.create(
  job_id: job4.id,
  pretax_pct: 5.0,
  roth_pct: 0.0,
  aftertax_pct: 0.0
)

puts '✓ Seeds created successfully!'
puts "  - 1 household (#{household.name})"
puts "  - 2 spouses (#{spouse1.name}, #{spouse2.name})"
puts '  - 4 jobs with varying configurations'
puts '  - 4 contribution settings'
puts "\nExample scenarios covered:"
puts '  ✓ Multiple overlapping jobs'
puts '  ✓ Different pay frequencies'
puts '  ✓ Bonuses and match configurations'
puts '  ✓ Mid-year job changes with starting YTD'
puts '  ✓ Mega backdoor Roth availability'
puts '  ✓ True-up matching'
