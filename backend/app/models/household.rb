# frozen_string_literal: true

require 'sequel'

# Household model - represents a tax filing unit
class Household < Sequel::Model
  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  # Associations
  one_to_many :spouses, dependent: :destroy

  # Valid values
  FILING_STATUSES = %w[single married_filing_jointly married_filing_separately head_of_household].freeze
  STATUSES = %w[draft in_progress complete].freeze

  # Validations
  def validate
    super
    validates_presence %i[name tax_year filing_status status]
    validates_includes FILING_STATUSES, :filing_status, message: 'must be a valid filing status'
    validates_includes STATUSES, :status, message: 'must be a valid status'
    validates_integer :tax_year, message: 'must be a valid year'

    errors.add(:tax_year, 'must be between 2020 and 2050') if tax_year && (tax_year < 2020 || tax_year > 2050)

    return unless state && state.length != 2

    errors.add(:state, 'must be a two-letter state code')
  end

  # Returns the next required step for workflow
  def next_step
    return 'add_spouses' if spouses.empty?
    return 'add_jobs' if spouses.all? { |s| s.jobs.empty? }
    return 'configure_contributions' if spouses.any? { |s| s.jobs.any? { |j| j.contribution_setting.nil? } }

    'view_results'
  end

  # Converts to hash for API response
  def to_api_hash
    {
      id: id,
      name: name,
      tax_year: tax_year,
      filing_status: filing_status,
      state: state,
      status: status,
      next_step: next_step,
      created_at: created_at.iso8601,
      updated_at: updated_at.iso8601
    }
  end
end
