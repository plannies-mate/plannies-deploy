# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'time'

require 'simplecov'
require 'simplecov-console'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'

  # Track files in lib directory
  add_group 'App', 'app'
  add_group 'Library', 'lib'
  add_group 'Tasks', 'tasks'
end

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console
  ]
)

require 'rspec'
require 'vcr'
require 'webmock/rspec'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
end

# Load all support files
Dir[File.expand_path('./support/**/*.rb', __dir__)].each { |f| require f }

# Load all files so they appear in coverage
Dir.glob(File.expand_path('../app/**/*.rb', __dir__)).each { |r| require r }
Dir.glob(File.expand_path('../lib/**/*.rb', __dir__)).each { |r| require r }

# Configure RSpec
RSpec.configure do |config|
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

  # Make it stop on the first failure. Makes in this case
  # for quicker debugging
  config.fail_fast = !ENV['FAIL_FAST'].to_s.empty?

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed
end
