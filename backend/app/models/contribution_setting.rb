# frozen_string_literal: true

require 'sequel'

# ContributionSetting model - represents 401k contribution percentages for a job
class ContributionSetting < Sequel::Model
  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  # Associations
  many_to_one :job

  # Validations
  def validate
    super
    validates_presence [:job_id]
    validates_integer :job_id

    # Validate percentage ranges (database constraints also enforce these)
    validates_operator :>=, 0, :pretax_pct, message: 'must be greater than or equal to 0'
    validates_operator :<=, 100, :pretax_pct, message: 'must be less than or equal to 100'
    validates_operator :>=, 0, :roth_pct, message: 'must be greater than or equal to 0'
    validates_operator :<=, 100, :roth_pct, message: 'must be less than or equal to 100'
    validates_operator :>=, 0, :aftertax_pct, message: 'must be greater than or equal to 0'
    validates_operator :<=, 100, :aftertax_pct, message: 'must be less than or equal to 100'

    # Validate total doesn't exceed 100%
    total = (pretax_pct || 0) + (roth_pct || 0) + (aftertax_pct || 0)
    errors.add(:base, 'total contribution percentage cannot exceed 100%') if total > 100
  end

  # Converts to hash for API response
  def to_api_hash
    {
      id: id,
      job_id: job_id,
      pretax_pct: pretax_pct,
      roth_pct: roth_pct,
      aftertax_pct: aftertax_pct,
      created_at: created_at.iso8601,
      updated_at: updated_at.iso8601
    }
  end
end
