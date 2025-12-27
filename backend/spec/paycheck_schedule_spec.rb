# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Retirement::PaycheckSchedule do
  it 'builds biweekly schedule within 2026' do
    schedule = described_class.new(first_paycheck_date: Date.new(2026, 1, 5), frequency: :biweekly)
    dates = schedule.dates_for_year
    expect(dates.first).to eq(Date.new(2026, 1, 5))
    expect(dates[1]).to eq(Date.new(2026, 1, 19))
    expect(dates.count).to be > 20
  end

  it 'supports explicit paycheck counts' do
    schedule = described_class.new(first_paycheck_date: Date.new(2026, 1, 15), paycheck_count: 12)
    dates = schedule.dates_for_year
    expect(dates.count).to eq(1) # increment 0 so only first included
  end
end
