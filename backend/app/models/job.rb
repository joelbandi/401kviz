# frozen_string_literal: true

require 'sequel'

# Job model - represents employment with compensation and 401k plan details
class Job < Sequel::Model
  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  # Associations
  many_to_one :spouse
  one_to_one :contribution_setting, dependent: :destroy

  # Valid values
  PAY_FREQUENCIES = %w[weekly biweekly semi_monthly monthly].freeze

  # Validations
  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def validate
    super
    validates_presence %i[spouse_id employer_name first_paycheck_date pay_frequency base_salary]
    validates_integer :spouse_id
    validates_includes PAY_FREQUENCIES, :pay_frequency, message: 'must be a valid pay frequency'
    validates_integer :base_salary, message: 'must be a valid amount'

    errors.add(:base_salary, 'must be greater than or equal to 0') if base_salary&.negative?

    errors.add(:bonus_amount, 'must be greater than or equal to 0') if bonus_amount&.negative?

    errors.add(:bonus_date, 'cannot be set without a bonus amount') if bonus_date && !bonus_amount.to_i.positive?

    if match_percent && (match_percent.negative? || match_percent > 100)
      errors.add(:match_percent, 'must be between 0 and 100')
    end

    if match_cap_percent && (match_cap_percent.negative? || match_cap_percent > 100)
      errors.add(:match_cap_percent, 'must be between 0 and 100')
    end

    # Validate starting YTD amounts are non-negative
    %i[starting_ytd_pretax starting_ytd_roth starting_ytd_aftertax starting_ytd_match].each do |field|
      value = send(field)
      errors.add(field, 'must be greater than or equal to 0') if value&.negative?
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  # Converts to hash for API response
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def to_api_hash
    {
      id: id,
      spouse_id: spouse_id,
      employer_name: employer_name,
      first_paycheck_date: first_paycheck_date.iso8601,
      pay_frequency: pay_frequency,
      base_salary: base_salary,
      bonus_amount: bonus_amount,
      bonus_date: bonus_date&.iso8601,
      pretax_enabled: pretax_enabled,
      roth_enabled: roth_enabled,
      aftertax_enabled: aftertax_enabled,
      mega_backdoor_allowed: mega_backdoor_allowed,
      match_percent: match_percent,
      match_cap_percent: match_cap_percent,
      true_up: true_up,
      starting_ytd_pretax: starting_ytd_pretax,
      starting_ytd_roth: starting_ytd_roth,
      starting_ytd_aftertax: starting_ytd_aftertax,
      starting_ytd_match: starting_ytd_match,
      created_at: created_at.iso8601,
      updated_at: updated_at.iso8601
    }
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
end
