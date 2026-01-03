ENV['RACK_ENV'] = 'test'

require 'rack/test'
require 'rspec'
require_relative '../app'

# Load models for tests
require_relative '../app/models/household'
require_relative '../app/models/spouse'
require_relative '../app/models/job'
require_relative '../app/models/contribution_setting'

module RSpecMixin
  include Rack::Test::Methods

  def app
    App
  end
end

RSpec.configure do |config|
  config.include RSpecMixin

  # Database cleanup - truncate tables before each test
  config.before do
    [ContributionSetting, Job, Spouse, Household].each(&:truncate)
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed
end
