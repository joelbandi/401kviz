# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'Household API' do
  describe 'GET /api/v1/households' do
    it 'returns empty array when no households exist' do
      get '/api/v1/households'
      expect(last_response.status).to eq(200)
      data = JSON.parse(last_response.body)
      expect(data['households']).to eq([])
    end

    it 'returns all households' do
      Household.create(
        name: 'Family 1',
        tax_year: 2026,
        filing_status: 'married_filing_jointly',
        status: 'draft'
      )
      Household.create(
        name: 'Family 2',
        tax_year: 2025,
        filing_status: 'single',
        status: 'complete'
      )

      get '/api/v1/households'
      expect(last_response.status).to eq(200)
      data = JSON.parse(last_response.body)
      expect(data['households'].length).to eq(2)
    end
  end

  describe 'GET /api/v1/households/:id' do
    let(:household) do
      Household.create(
        name: 'Test Family',
        tax_year: 2026,
        filing_status: 'married_filing_jointly',
        status: 'draft'
      )
    end

    it 'returns household with spouses' do
      Spouse.create(household_id: household.id, name: 'Test Spouse')

      get "/api/v1/households/#{household.id}"
      expect(last_response.status).to eq(200)
      data = JSON.parse(last_response.body)
      expect(data['id']).to eq(household.id)
      expect(data['name']).to eq('Test Family')
      expect(data['spouses']).to be_an(Array)
      expect(data['spouses'].length).to eq(1)
    end

    it 'returns 404 for non-existent household' do
      get '/api/v1/households/99999'
      expect(last_response.status).to eq(404)
      data = JSON.parse(last_response.body)
      expect(data['error'].downcase).to include('not found')
    end
  end

  describe 'POST /api/v1/households' do
    it 'creates a new household' do
      post '/api/v1/households',
           { name: 'New Family', tax_year: 2026, filing_status: 'single' }.to_json,
           'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(201)
      data = JSON.parse(last_response.body)
      expect(data['name']).to eq('New Family')
      expect(data['tax_year']).to eq(2026)
      expect(data['filing_status']).to eq('single')
      expect(data['status']).to eq('draft')
    end

    it 'returns 400 for missing required fields' do
      post '/api/v1/households',
           { name: 'New Family' }.to_json,
           'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(400)
      data = JSON.parse(last_response.body)
      expect(data['error']).to include('Missing required fields')
    end

    it 'returns 400 for invalid filing_status' do
      post '/api/v1/households',
           { name: 'New Family', tax_year: 2026, filing_status: 'invalid' }.to_json,
           'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(400)
      data = JSON.parse(last_response.body)
      expect(data['error']).to eq('Validation failed')
    end
  end

  describe 'PUT /api/v1/households/:id' do
    let(:household) do
      Household.create(
        name: 'Test Family',
        tax_year: 2026,
        filing_status: 'married_filing_jointly',
        status: 'draft'
      )
    end

    it 'updates a household' do
      put "/api/v1/households/#{household.id}",
          { name: 'Updated Family' }.to_json,
          'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(200)
      data = JSON.parse(last_response.body)
      expect(data['name']).to eq('Updated Family')
    end

    it 'returns 404 for non-existent household' do
      put '/api/v1/households/99999',
          { name: 'Updated Family' }.to_json,
          'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(404)
    end
  end

  describe 'DELETE /api/v1/households/:id' do
    let(:household) do
      Household.create(
        name: 'Test Family',
        tax_year: 2026,
        filing_status: 'married_filing_jointly',
        status: 'draft'
      )
    end

    it 'deletes a household' do
      delete "/api/v1/households/#{household.id}"
      expect(last_response.status).to eq(204)
      expect(Household[household.id]).to be_nil
    end

    it 'returns 404 for non-existent household' do
      delete '/api/v1/households/99999'
      expect(last_response.status).to eq(404)
    end
  end
end
