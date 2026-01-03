# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/models/household'
require_relative '../../app/models/spouse'

RSpec.describe Household do
  describe 'validations' do
    it 'creates a valid household' do
      household = described_class.new(
        name: 'Test Family',
        tax_year: 2026,
        filing_status: 'married_filing_jointly',
        status: 'draft'
      )
      expect(household).to be_valid
    end

    it 'requires name' do
      household = described_class.new(tax_year: 2026, filing_status: 'single', status: 'draft')
      expect(household).not_to be_valid
      expect(household.errors[:name]).to include('is not present')
    end

    it 'requires tax_year' do
      household = described_class.new(name: 'Test', filing_status: 'single', status: 'draft')
      expect(household).not_to be_valid
      expect(household.errors[:tax_year]).to include('is not present')
    end

    it 'requires filing_status' do
      household = described_class.new(name: 'Test', tax_year: 2026, status: 'draft')
      expect(household).not_to be_valid
      expect(household.errors[:filing_status]).to include('is not present')
    end

    it 'validates filing_status is valid' do
      household = described_class.new(
        name: 'Test',
        tax_year: 2026,
        filing_status: 'invalid',
        status: 'draft'
      )
      expect(household).not_to be_valid
      expect(household.errors[:filing_status]).to include('must be a valid filing status')
    end

    it 'validates status is valid' do
      household = described_class.new(
        name: 'Test',
        tax_year: 2026,
        filing_status: 'single',
        status: 'invalid'
      )
      expect(household).not_to be_valid
      expect(household.errors[:status]).to include('must be a valid status')
    end

    it 'validates tax_year is in range' do
      household = described_class.new(
        name: 'Test',
        tax_year: 2010,
        filing_status: 'single',
        status: 'draft'
      )
      expect(household).not_to be_valid
      expect(household.errors[:tax_year]).to include('must be between 2020 and 2050')
    end

    it 'validates state is two letters' do
      household = described_class.new(
        name: 'Test',
        tax_year: 2026,
        filing_status: 'single',
        state: 'California',
        status: 'draft'
      )
      expect(household).not_to be_valid
      expect(household.errors[:state]).to include('must be a two-letter state code')
    end
  end

  describe 'associations' do
    it 'has many spouses' do
      household = described_class.create(
        name: 'Test Family',
        tax_year: 2026,
        filing_status: 'married_filing_jointly',
        status: 'draft'
      )

      spouse1 = Spouse.create(household_id: household.id, name: 'Spouse 1')
      spouse2 = Spouse.create(household_id: household.id, name: 'Spouse 2')

      expect(household.spouses.count).to eq(2)
      expect(household.spouses).to include(spouse1, spouse2)
    end
  end

  describe '#next_step' do
    let(:household) do
      described_class.create(
        name: 'Test Family',
        tax_year: 2026,
        filing_status: 'married_filing_jointly',
        status: 'draft'
      )
    end

    it 'returns add_spouses when no spouses exist' do
      expect(household.next_step).to eq('add_spouses')
    end

    it 'returns add_jobs when spouses have no jobs' do
      Spouse.create(household_id: household.id, name: 'Spouse 1')
      expect(household.next_step).to eq('add_jobs')
    end
  end

  describe '#to_api_hash' do
    it 'returns hash with expected keys' do
      household = described_class.create(
        name: 'Test Family',
        tax_year: 2026,
        filing_status: 'married_filing_jointly',
        state: 'CA',
        status: 'draft'
      )

      hash = household.to_api_hash
      expect(hash).to include(
        :id,
        :name,
        :tax_year,
        :filing_status,
        :state,
        :status,
        :next_step,
        :created_at,
        :updated_at
      )
    end
  end
end
