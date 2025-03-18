# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'simplecov'
require 'simplecov-console'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console
  ]
)
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'

  add_group 'Controllers', 'app/controllers'
  add_group 'Helpers', 'app/helpers'
  add_group 'Library', 'lib'
  add_group 'Tasks', 'tasks'
end

require 'fileutils'
require 'json'
require 'time'
require 'tempfile'
require 'rspec'
require 'vcr'
require 'webmock/rspec'

VCR.configure do |config|
  config.allow_http_connections_when_no_cassette = false
  config.cassette_library_dir = File.expand_path('cassettes', __dir__)
  config.hook_into :webmock
  config.ignore_request { ENV.fetch('DISABLE_VCR', nil) }
  config.ignore_localhost = true
  config.configure_rspec_metadata!

  # Filter out sensitive information if needed
  # config.filter_sensitive_data('<API_KEY>') { ENV['API_KEY'] }

  # Allow localhost requests (useful for testing against local services)
  config.ignore_localhost = true

  # Set default recording mode - one of :once, :new_episodes, :none, :all
  vcr_mode = ENV.fetch('VCR_MODE', nil) =~ /rec/i ? :all : :once
  config.default_cassette_options = {
    record: vcr_mode,
    match_requests_on: %i[method uri body]
  }
end

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

  # Create VCR cassette directory if it doesn't exist
  config.before(:suite) do
    FileUtils.mkdir_p('spec/fixtures/vcr_cassettes')
  end
end

# Helper method to create a temporary directory
def create_temp_dir(prefix = 'test')
  path = File.join(Dir.tmpdir, "#{prefix}_#{Time.now.to_i}_#{rand(1000)}")
  FileUtils.mkdir_p(path)
  path
end

# Load all support files
Dir[File.expand_path('./support/**/*.rb', __dir__)].each { |f| require f }

# Load all files so they appear in coverage
Dir.glob(File.expand_path('../app/**/*.rb', __dir__)).each { |r| require r }
Dir.glob(File.expand_path('../lib/**/*.rb', __dir__)).each { |r| require r }
