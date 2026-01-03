# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/models/household'
require_relative '../../app/models/spouse'
require_relative '../../app/models/job'

RSpec.describe Job do
  let(:household) do
    Household.create(
      name: 'Test Family',
      tax_year: 2026,
      filing_status: 'married_filing_jointly',
      status: 'draft'
    )
  end

  let(:spouse) do
    Spouse.create(household_id: household.id, name: 'Test Spouse')
  end

  describe 'validations' do
    it 'creates a valid job' do
      job = described_class.new(
        spouse_id: spouse.id,
        employer_name: 'Test Corp',
        first_paycheck_date: Date.new(2026, 1, 15),
        pay_frequency: 'biweekly',
        base_salary: 10_000_000
      )
      expect(job).to be_valid
    end

    it 'requires spouse_id' do
      job = described_class.new(
        employer_name: 'Test Corp',
        first_paycheck_date: Date.new(2026, 1, 15),
        pay_frequency: 'biweekly',
        base_salary: 10_000_000
      )
      expect(job).not_to be_valid
      expect(job.errors[:spouse_id]).to include('is not present')
    end

    it 'requires employer_name' do
      job = described_class.new(
        spouse_id: spouse.id,
        first_paycheck_date: Date.new(2026, 1, 15),
        pay_frequency: 'biweekly',
        base_salary: 10_000_000
      )
      expect(job).not_to be_valid
      expect(job.errors[:employer_name]).to include('is not present')
    end

    it 'validates pay_frequency' do
      job = described_class.new(
        spouse_id: spouse.id,
        employer_name: 'Test Corp',
        first_paycheck_date: Date.new(2026, 1, 15),
        pay_frequency: 'invalid',
        base_salary: 10_000_000
      )
      expect(job).not_to be_valid
      expect(job.errors[:pay_frequency]).to include('must be a valid pay frequency')
    end

    it 'validates base_salary is non-negative' do
      job = described_class.new(
        spouse_id: spouse.id,
        employer_name: 'Test Corp',
        first_paycheck_date: Date.new(2026, 1, 15),
        pay_frequency: 'biweekly',
        base_salary: -100
      )
      expect(job).not_to be_valid
      expect(job.errors[:base_salary]).to include('must be greater than or equal to 0')
    end

    it 'validates bonus_amount is non-negative' do
      job = described_class.new(
        spouse_id: spouse.id,
        employer_name: 'Test Corp',
        first_paycheck_date: Date.new(2026, 1, 15),
        pay_frequency: 'biweekly',
        base_salary: 10_000_000,
        bonus_amount: -100
      )
      expect(job).not_to be_valid
      expect(job.errors[:bonus_amount]).to include('must be greater than or equal to 0')
    end

    it 'validates match_percent is in range' do
      job = described_class.new(
        spouse_id: spouse.id,
        employer_name: 'Test Corp',
        first_paycheck_date: Date.new(2026, 1, 15),
        pay_frequency: 'biweekly',
        base_salary: 10_000_000,
        match_percent: 150.0
      )
      expect(job).not_to be_valid
      expect(job.errors[:match_percent]).to include('must be between 0 and 100')
    end
  end

  describe '#to_api_hash' do
    it 'returns hash with expected keys' do
      job = described_class.create(
        spouse_id: spouse.id,
        employer_name: 'Test Corp',
        first_paycheck_date: Date.new(2026, 1, 15),
        pay_frequency: 'biweekly',
        base_salary: 10_000_000,
        match_percent: 50.0,
        match_cap_percent: 6.0
      )

      hash = job.to_api_hash
      expect(hash).to include(
        :id,
        :spouse_id,
        :employer_name,
        :first_paycheck_date,
        :pay_frequency,
        :base_salary,
        :match_percent,
        :match_cap_percent
      )
    end
  end
end
