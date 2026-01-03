# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'IRS Configuration API' do
  describe 'GET /api/v1/config/tax-years' do
    before { get '/api/v1/config/tax-years' }

    it 'returns 200 OK' do
      expect(last_response.status).to eq(200)
    end

    it 'returns JSON' do
      expect(last_response.content_type).to include('application/json')
    end

    it 'returns years array' do
      data = JSON.parse(last_response.body)
      expect(data['years']).to be_an(Array)
      expect(data['years']).to include(2024, 2025, 2026)
    end

    it 'returns sorted years' do
      data = JSON.parse(last_response.body)
      expect(data['years']).to eq(data['years'].sort)
    end

    it 'returns default year' do
      data = JSON.parse(last_response.body)
      expect(data['default_year']).to be_an(Integer)
      expect(data['default_year']).to eq(2026)
    end

    it 'default year is the highest available year' do
      data = JSON.parse(last_response.body)
      expect(data['default_year']).to eq(data['years'].max)
    end
  end

  describe 'GET /api/v1/config/tax-year/:year' do
    context 'with valid existing year' do
      before { get '/api/v1/config/tax-year/2026' }

      it 'returns 200 OK' do
        expect(last_response.status).to eq(200)
      end

      it 'returns JSON' do
        expect(last_response.content_type).to include('application/json')
      end

      it 'returns year in response' do
        data = JSON.parse(last_response.body)
        expect(data['year']).to eq(2026)
      end

      it 'returns config object' do
        data = JSON.parse(last_response.body)
        expect(data['config']).to be_a(Hash)
      end

      it 'returns required configuration values as integers' do
        data = JSON.parse(last_response.body)
        config = data['config']

        expect(config['employee_deferral_limit']).to eq(24_500)
        expect(config['total_401k_limit']).to eq(72_000)
        expect(config['catch_up_contribution']).to eq(7500)
      end

      it 'returns optional HSA configuration values' do
        data = JSON.parse(last_response.body)
        config = data['config']

        expect(config['hsa_individual_limit']).to eq(4300)
        expect(config['hsa_family_limit']).to eq(8550)
      end

      it 'all values are integers not strings' do
        data = JSON.parse(last_response.body)
        config = data['config']

        config.each do |key, value|
          expect(value).to be_an(Integer), "Expected #{key} to be Integer, got #{value.class}"
        end
      end
    end

    context 'with year 2025' do
      before { get '/api/v1/config/tax-year/2025' }

      it 'returns correct values for 2025' do
        data = JSON.parse(last_response.body)
        config = data['config']

        expect(config['employee_deferral_limit']).to eq(23_500)
        expect(config['total_401k_limit']).to eq(70_000)
      end
    end

    context 'with year 2024' do
      before { get '/api/v1/config/tax-year/2024' }

      it 'returns correct values for 2024' do
        data = JSON.parse(last_response.body)
        config = data['config']

        expect(config['employee_deferral_limit']).to eq(23_000)
        expect(config['total_401k_limit']).to eq(69_000)
      end
    end

    context 'with year below valid range' do
      before { get '/api/v1/config/tax-year/2019' }

      it 'returns 400 Bad Request' do
        expect(last_response.status).to eq(400)
      end

      it 'returns error message' do
        data = JSON.parse(last_response.body)
        expect(data['error']).to include('outside valid range')
      end
    end

    context 'with year above valid range' do
      before { get '/api/v1/config/tax-year/2051' }

      it 'returns 400 Bad Request' do
        expect(last_response.status).to eq(400)
      end

      it 'returns error message' do
        data = JSON.parse(last_response.body)
        expect(data['error']).to include('outside valid range')
      end
    end

    context 'with non-existent year in valid range' do
      before { get '/api/v1/config/tax-year/2030' }

      it 'returns 404 Not Found' do
        expect(last_response.status).to eq(404)
      end

      it 'returns error message' do
        data = JSON.parse(last_response.body)
        expect(data['error'].downcase).to include('not found')
      end
    end

    context 'with invalid year format' do
      before { get '/api/v1/config/tax-year/abc' }

      it 'returns 400 Bad Request' do
        expect(last_response.status).to eq(400)
      end

      it 'returns error message about invalid parameter' do
        data = JSON.parse(last_response.body)
        expect(data['error']).to include('must be a positive integer')
      end
    end
  end

  describe 'POST /api/v1/config/cache/refresh' do
    before { post '/api/v1/config/cache/refresh' }

    it 'returns 200 OK' do
      expect(last_response.status).to eq(200)
    end

    it 'returns JSON' do
      expect(last_response.content_type).to include('application/json')
    end

    it 'returns success message' do
      data = JSON.parse(last_response.body)
      expect(data['message']).to include('successfully')
    end

    it 'returns years_loaded array' do
      data = JSON.parse(last_response.body)
      expect(data['years_loaded']).to be_an(Array)
      expect(data['years_loaded']).to include(2024, 2025, 2026)
    end

    it 'returns default_year' do
      data = JSON.parse(last_response.body)
      expect(data['default_year']).to eq(2026)
    end

    it 'actually refreshes the cache' do
      # First load a config to populate cache
      get '/api/v1/config/tax-year/2026'
      expect(last_response.status).to eq(200)

      # Refresh cache
      post '/api/v1/config/cache/refresh'
      expect(last_response.status).to eq(200)

      # Verify we can still load configs
      get '/api/v1/config/tax-year/2026'
      expect(last_response.status).to eq(200)
    end
  end
end
