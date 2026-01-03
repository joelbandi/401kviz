# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Job API' do
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

  describe 'GET /api/v1/spouses/:spouse_id/jobs' do
    it 'returns empty array when no jobs exist' do
      get "/api/v1/spouses/#{spouse.id}/jobs"
      expect(last_response.status).to eq(200)
      data = JSON.parse(last_response.body)
      expect(data['jobs']).to eq([])
    end

    it 'returns all jobs for a spouse' do
      Job.create(
        spouse_id: spouse.id,
        employer_name: 'Company A',
        first_paycheck_date: Date.new(2026, 1, 15),
        pay_frequency: 'biweekly',
        base_salary: 10_000_000
      )
      Job.create(
        spouse_id: spouse.id,
        employer_name: 'Company B',
        first_paycheck_date: Date.new(2026, 6, 1),
        pay_frequency: 'monthly',
        base_salary: 5_000_000
      )

      get "/api/v1/spouses/#{spouse.id}/jobs"
      expect(last_response.status).to eq(200)
      data = JSON.parse(last_response.body)
      expect(data['jobs'].length).to eq(2)
    end
  end

  describe 'GET /api/v1/jobs/:id' do
    let(:job) do
      Job.create(
        spouse_id: spouse.id,
        employer_name: 'Test Corp',
        first_paycheck_date: Date.new(2026, 1, 15),
        pay_frequency: 'biweekly',
        base_salary: 10_000_000,
        match_percent: 50.0,
        match_cap_percent: 6.0
      )
    end

    it 'returns job details' do
      get "/api/v1/jobs/#{job.id}"
      expect(last_response.status).to eq(200)
      data = JSON.parse(last_response.body)
      expect(data['id']).to eq(job.id)
      expect(data['employer_name']).to eq('Test Corp')
      expect(data['base_salary']).to eq(10_000_000)
    end

    it 'returns 404 for non-existent job' do
      get '/api/v1/jobs/99999'
      expect(last_response.status).to eq(404)
    end
  end

  describe 'POST /api/v1/spouses/:spouse_id/jobs' do
    it 'creates a new job' do
      post "/api/v1/spouses/#{spouse.id}/jobs",
           {
             employer_name: 'New Corp',
             first_paycheck_date: '2026-01-15',
             pay_frequency: 'biweekly',
             base_salary: 12_000_000,
             match_percent: 50.0,
             match_cap_percent: 6.0
           }.to_json,
           'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(201)
      data = JSON.parse(last_response.body)
      expect(data['employer_name']).to eq('New Corp')
      expect(data['base_salary']).to eq(12_000_000)
      expect(data['match_percent']).to eq(50.0)
    end

    it 'returns 400 for missing required fields' do
      post "/api/v1/spouses/#{spouse.id}/jobs",
           { employer_name: 'New Corp' }.to_json,
           'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(400)
      data = JSON.parse(last_response.body)
      expect(data['error']).to include('Missing required fields')
    end

    it 'returns 400 for invalid pay_frequency' do
      post "/api/v1/spouses/#{spouse.id}/jobs",
           {
             employer_name: 'New Corp',
             first_paycheck_date: '2026-01-15',
             pay_frequency: 'invalid',
             base_salary: 12_000_000
           }.to_json,
           'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(400)
      data = JSON.parse(last_response.body)
      expect(data['error']).to eq('Validation failed')
    end
  end

  describe 'PUT /api/v1/jobs/:id' do
    let(:job) do
      Job.create(
        spouse_id: spouse.id,
        employer_name: 'Test Corp',
        first_paycheck_date: Date.new(2026, 1, 15),
        pay_frequency: 'biweekly',
        base_salary: 10_000_000
      )
    end

    it 'updates a job' do
      put "/api/v1/jobs/#{job.id}",
          { employer_name: 'Updated Corp', base_salary: 15_000_000 }.to_json,
          'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(200)
      data = JSON.parse(last_response.body)
      expect(data['employer_name']).to eq('Updated Corp')
      expect(data['base_salary']).to eq(15_000_000)
    end

    it 'returns 404 for non-existent job' do
      put '/api/v1/jobs/99999',
          { employer_name: 'Updated Corp' }.to_json,
          'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(404)
    end
  end

  describe 'DELETE /api/v1/jobs/:id' do
    let(:job) do
      Job.create(
        spouse_id: spouse.id,
        employer_name: 'Test Corp',
        first_paycheck_date: Date.new(2026, 1, 15),
        pay_frequency: 'biweekly',
        base_salary: 10_000_000
      )
    end

    it 'deletes a job' do
      delete "/api/v1/jobs/#{job.id}"
      expect(last_response.status).to eq(204)
      expect(Job[job.id]).to be_nil
    end

    it 'returns 404 for non-existent job' do
      delete '/api/v1/jobs/99999'
      expect(last_response.status).to eq(404)
    end
  end
end
