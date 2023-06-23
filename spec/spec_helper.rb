# frozen_string_literal: true

require 'webmock'
require 'vcr'
require 'simplecov'
SimpleCov.start

require 'event_hub_aws'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Configure VCR
  VCR.configure do |c|
    c.cassette_library_dir = 'spec/fixtures/vcr'
    c.hook_into :webmock
    c.default_cassette_options[:match_requests_on] << :body

    # c.filter_sensitive_data('<CREDENTIALS>') { ENV['CREDENTIALS'] }
  end

  config.around(:each, :vcr) do |example|
    name = example.metadata[:vcr]
    VCR.use_cassette(name) { example.call }
  end
end
