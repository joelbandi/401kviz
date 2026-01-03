# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../lib/irs_config/loader'

RSpec.describe IrsConfig::Loader do
  describe '.discover_years' do
    it 'returns array of years from irs_data directory' do
      years = described_class.discover_years

      expect(years).to be_an(Array)
      expect(years).to include(2024, 2025, 2026)
      expect(years).to eq(years.sort) # Should be sorted
    end

    it 'returns only positive integers' do
      years = described_class.discover_years

      years.each do |year|
        expect(year).to be_a(Integer)
        expect(year).to be > 0
      end
    end

    it 'returns empty array if directory does not exist' do
      # Stub Dir.exist? to return false
      allow(Dir).to receive(:exist?).and_return(false)

      years = described_class.discover_years
      expect(years).to eq([])
    end
  end

  describe '.load_config' do
    context 'with existing year' do
      it 'loads 2026 configuration' do
        config = described_class.load_config(2026)

        expect(config).to be_a(Hash)
        expect(config['EMPLOYEE_DEFERRAL_LIMIT']).to eq('24500')
        expect(config['TOTAL_401K_LIMIT']).to eq('72000')
        expect(config['CATCH_UP_CONTRIBUTION']).to eq('7500')
      end

      it 'loads 2025 configuration' do
        config = described_class.load_config(2025)

        expect(config).to be_a(Hash)
        expect(config['EMPLOYEE_DEFERRAL_LIMIT']).to eq('23500')
        expect(config['TOTAL_401K_LIMIT']).to eq('70000')
      end

      it 'loads 2024 configuration' do
        config = described_class.load_config(2024)

        expect(config).to be_a(Hash)
        expect(config['EMPLOYEE_DEFERRAL_LIMIT']).to eq('23000')
        expect(config['TOTAL_401K_LIMIT']).to eq('69000')
      end

      it 'includes optional HSA keys if present' do
        config = described_class.load_config(2026)

        expect(config['HSA_INDIVIDUAL_LIMIT']).to eq('4300')
        expect(config['HSA_FAMILY_LIMIT']).to eq('8550')
      end
    end

    context 'with non-existing year' do
      it 'raises LoadError for missing file' do
        expect do
          described_class.load_config(2099)
        end.to raise_error(IrsConfig::Loader::LoadError, /not found/)
      end

      it 'includes year in error message' do
        expect do
          described_class.load_config(2099)
        end.to raise_error(IrsConfig::Loader::LoadError, /2099/)
      end
    end

    context 'with invalid file' do
      it 'raises LoadError for empty file' do
        # Create a temporary empty file
        empty_file = File.join(described_class::IRS_DATA_DIR, 'empty_test.env')
        File.write(empty_file, '')

        expect do
          described_class.send(:parse_env_file, empty_file)
        end.to raise_error(IrsConfig::Loader::LoadError, /empty or invalid/)

        # Cleanup
        FileUtils.rm_f(empty_file)
      end
    end
  end
end
