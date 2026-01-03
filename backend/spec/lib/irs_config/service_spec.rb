# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../lib/irs_config/service'

RSpec.describe IrsConfig::Service do
  let(:service) { described_class.new }

  describe '#available_years' do
    it 'returns array of available years' do
      years = service.available_years

      expect(years).to be_an(Array)
      expect(years).to include(2024, 2025, 2026)
      expect(years).to eq(years.sort)
    end

    it 'caches the result on subsequent calls' do
      # First call
      years1 = service.available_years

      # Mock Loader to verify it's not called again
      expect(IrsConfig::Loader).not_to receive(:discover_years)

      # Second call should return cached value
      years2 = service.available_years

      expect(years1).to eq(years2)
    end

    it 'raises ConfigurationError if no configs found' do
      # Stub Loader to return empty array
      allow(IrsConfig::Loader).to receive(:discover_years).and_return([])

      expect do
        service.available_years
      end.to raise_error(IrsConfig::ConfigurationError, /No IRS configuration files found/)
    end
  end

  describe '#default_year' do
    it 'returns the highest available year' do
      default = service.default_year

      expect(default).to be_an(Integer)
      expect(default).to eq(2026) # Highest year in test data
    end

    it 'is the maximum of available years' do
      years = service.available_years
      default = service.default_year

      expect(default).to eq(years.max)
    end
  end

  describe '#get_config' do
    context 'with valid year' do
      it 'returns configuration for 2026' do
        config = service.get_config(2026)

        expect(config).to be_a(Hash)
        expect(config[:employee_deferral_limit]).to eq(24_500)
        expect(config[:total_401k_limit]).to eq(72_000)
        expect(config[:catch_up_contribution]).to eq(7500)
      end

      it 'returns symbolized keys' do
        config = service.get_config(2026)

        expect(config.keys).to all(be_a(Symbol))
        expect(config.keys).to include(
          :employee_deferral_limit,
          :total_401k_limit,
          :catch_up_contribution
        )
      end

      it 'returns integer values' do
        config = service.get_config(2026)

        config.each do |key, value|
          expect(value).to be_an(Integer), "Expected #{key} to be Integer, got #{value.class}"
        end
      end

      it 'includes optional HSA keys if present' do
        config = service.get_config(2026)

        expect(config[:hsa_individual_limit]).to eq(4300)
        expect(config[:hsa_family_limit]).to eq(8550)
      end

      it 'caches configuration on subsequent calls' do
        # First call
        config1 = service.get_config(2026)

        # Mock Loader to verify it's not called again
        expect(IrsConfig::Loader).not_to receive(:load_config)

        # Second call should return cached value
        config2 = service.get_config(2026)

        expect(config1).to eq(config2)
        expect(config1.object_id).to eq(config2.object_id) # Same object
      end
    end

    context 'with invalid year' do
      it 'raises YearOutOfRangeError for year below range' do
        expect do
          service.get_config(2019)
        end.to raise_error(IrsConfig::YearOutOfRangeError, /outside valid range/)
      end

      it 'raises YearOutOfRangeError for year above range' do
        expect do
          service.get_config(2051)
        end.to raise_error(IrsConfig::YearOutOfRangeError, /outside valid range/)
      end

      it 'raises ConfigNotFoundError for non-existent year in range' do
        expect do
          service.get_config(2030)
        end.to raise_error(IrsConfig::ConfigNotFoundError, /not found/)
      end
    end
  end

  describe '#validate_startup!' do
    it 'succeeds with valid configurations' do
      expect { service.validate_startup! }.not_to raise_error
    end

    it 'returns true on success' do
      result = service.validate_startup!
      expect(result).to be true
    end

    it 'loads default year configuration' do
      service.validate_startup!

      # Default year config should be cached
      default_year = service.default_year
      expect(service.instance_variable_get(:@cache)).to have_key(default_year)
    end

    it 'raises ConfigurationError if no configs found' do
      allow(IrsConfig::Loader).to receive(:discover_years).and_return([])

      expect do
        service.validate_startup!
      end.to raise_error(IrsConfig::ConfigurationError, /No IRS configuration/)
    end

    it 'raises ConfigurationError if default config is invalid' do
      allow(IrsConfig::Validator).to receive(:validate_config).and_return([false, 'Invalid config'])

      expect do
        service.validate_startup!
      end.to raise_error(IrsConfig::ConfigurationError)
    end
  end

  describe '#clear_cache!' do
    it 'clears cached configurations' do
      # Load some configs
      service.get_config(2026)
      service.get_config(2025)

      expect(service.instance_variable_get(:@cache)).not_to be_empty

      # Clear cache
      service.clear_cache!

      expect(service.instance_variable_get(:@cache)).to be_empty
    end

    it 'clears cached available years' do
      # Load available years
      service.available_years

      expect(service.instance_variable_get(:@available_years)).not_to be_nil

      # Clear cache
      service.clear_cache!

      expect(service.instance_variable_get(:@available_years)).to be_nil
    end

    it 'allows reloading after clear' do
      # Load config
      config1 = service.get_config(2026)

      # Clear and reload
      service.clear_cache!
      config2 = service.get_config(2026)

      expect(config1).to eq(config2)
    end
  end
end
