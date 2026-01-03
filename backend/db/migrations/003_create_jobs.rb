# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:jobs) do
      primary_key :id
      foreign_key :spouse_id, :spouses, null: false, on_delete: :cascade

      # Basic job information
      String :employer_name, null: false
      Date :first_paycheck_date, null: false
      String :pay_frequency, null: false # weekly, biweekly, semi_monthly, monthly

      # Compensation
      Integer :base_salary, null: false # Annual salary in cents
      Integer :bonus_amount, default: 0 # Bonus in cents
      Date :bonus_date # Date when bonus is paid

      # 401k plan flags
      TrueClass :pretax_enabled, null: false, default: true
      TrueClass :roth_enabled, null: false, default: true
      TrueClass :aftertax_enabled, null: false, default: false
      TrueClass :mega_backdoor_allowed, null: false, default: false

      # Employer match configuration
      Float :match_percent, default: 0.0 # e.g., 50.0 for 50%
      Float :match_cap_percent, default: 0.0 # e.g., 6.0 for 6% of salary
      TrueClass :true_up, null: false, default: false

      # Starting YTD contributions (in cents)
      Integer :starting_ytd_pretax, default: 0
      Integer :starting_ytd_roth, default: 0
      Integer :starting_ytd_aftertax, default: 0
      Integer :starting_ytd_match, default: 0

      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index :spouse_id
      index :first_paycheck_date
    end
  end
end
