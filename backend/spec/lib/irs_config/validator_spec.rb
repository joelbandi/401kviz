# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../lib/irs_config/validator'

RSpec.describe IrsConfig::Validator do
  describe '.validate_year' do
    context 'with valid years' do
      it 'accepts year 2020 (minimum)' do
        valid, error = described_class.validate_year(2020)
        expect(valid).to be true
        expect(error).to be_nil
      end

      it 'accepts year 2050 (maximum)' do
        valid, error = described_class.validate_year(2050)
        expect(valid).to be true
        expect(error).to be_nil
      end

      it 'accepts year 2026 (middle of range)' do
        valid, error = described_class.validate_year(2026)
        expect(valid).to be true
        expect(error).to be_nil
      end
    end

    context 'with invalid years' do
      it 'rejects year below 2020' do
        valid, error = described_class.validate_year(2019)
        expect(valid).to be false
        expect(error).to include('outside valid range')
        expect(error).to include('2020-2050')
      end

      it 'rejects year above 2050' do
        valid, error = described_class.validate_year(2051)
        expect(valid).to be false
        expect(error).to include('outside valid range')
      end

      it 'rejects non-integer year' do
        valid, error = described_class.validate_year('2026')
        expect(valid).to be false
        expect(error).to include('must be an integer')
      end

      it 'rejects nil year' do
        valid, error = described_class.validate_year(nil)
        expect(valid).to be false
        expect(error).to include('must be an integer')
      end
    end
  end

  describe '.validate_config' do
    let(:valid_config) do
      {
        'EMPLOYEE_DEFERRAL_LIMIT' => '24500',
        'TOTAL_401K_LIMIT' => '72000',
        'CATCH_UP_CONTRIBUTION' => '7500',
        'HSA_INDIVIDUAL_LIMIT' => '4300',
        'HSA_FAMILY_LIMIT' => '8550'
      }
    end

    context 'with valid configuration' do
      it 'accepts config with all required and optional keys' do
        valid, error = described_class.validate_config(valid_config, 2026)
        expect(valid).to be true
        expect(error).to be_nil
      end

      it 'accepts config with only required keys' do
        minimal_config = {
          'EMPLOYEE_DEFERRAL_LIMIT' => '24500',
          'TOTAL_401K_LIMIT' => '72000',
          'CATCH_UP_CONTRIBUTION' => '7500'
        }

        valid, error = described_class.validate_config(minimal_config, 2026)
        expect(valid).to be true
        expect(error).to be_nil
      end
    end

    context 'with missing required keys' do
      it 'rejects config missing EMPLOYEE_DEFERRAL_LIMIT' do
        config = valid_config.dup
        config.delete('EMPLOYEE_DEFERRAL_LIMIT')

        valid, error = described_class.validate_config(config, 2026)
        expect(valid).to be false
        expect(error).to include('Missing required keys')
        expect(error).to include('EMPLOYEE_DEFERRAL_LIMIT')
      end

      it 'rejects config missing TOTAL_401K_LIMIT' do
        config = valid_config.dup
        config.delete('TOTAL_401K_LIMIT')

        valid, error = described_class.validate_config(config, 2026)
        expect(valid).to be false
        expect(error).to include('TOTAL_401K_LIMIT')
      end

      it 'rejects config missing CATCH_UP_CONTRIBUTION' do
        config = valid_config.dup
        config.delete('CATCH_UP_CONTRIBUTION')

        valid, error = described_class.validate_config(config, 2026)
        expect(valid).to be false
        expect(error).to include('CATCH_UP_CONTRIBUTION')
      end

      it 'rejects config missing multiple required keys' do
        config = { 'HSA_INDIVIDUAL_LIMIT' => '4300' }

        valid, error = described_class.validate_config(config, 2026)
        expect(valid).to be false
        expect(error).to include('Missing required keys')
      end
    end

    context 'with invalid values' do
      it 'rejects non-numeric value' do
        config = valid_config.dup
        config['EMPLOYEE_DEFERRAL_LIMIT'] = 'abc'

        valid, error = described_class.validate_config(config, 2026)
        expect(valid).to be false
        expect(error).to include('not a positive integer')
      end

      it 'rejects negative value' do
        config = valid_config.dup
        config['TOTAL_401K_LIMIT'] = '-100'

        valid, error = described_class.validate_config(config, 2026)
        expect(valid).to be false
        expect(error).to include('not a positive integer')
      end

      it 'rejects zero value' do
        config = valid_config.dup
        config['CATCH_UP_CONTRIBUTION'] = '0'

        valid, error = described_class.validate_config(config, 2026)
        expect(valid).to be false
        expect(error).to include('must be greater than 0')
      end

      it 'rejects decimal value' do
        config = valid_config.dup
        config['EMPLOYEE_DEFERRAL_LIMIT'] = '24500.50'

        valid, error = described_class.validate_config(config, 2026)
        expect(valid).to be false
        expect(error).to include('not a positive integer')
      end
    end
  end
end
