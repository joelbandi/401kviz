# frozen_string_literal: true

require 'sequel'

# Spouse model - represents an individual in a household
class Spouse < Sequel::Model
  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  # Associations
  many_to_one :household
  one_to_many :jobs, dependent: :destroy

  # Validations
  def validate
    super
    validates_presence %i[household_id name]
    validates_integer :household_id
  end

  # Converts to hash for API response
  def to_api_hash
    {
      id: id,
      household_id: household_id,
      name: name,
      created_at: created_at.iso8601,
      updated_at: updated_at.iso8601
    }
  end
end
