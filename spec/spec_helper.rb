# frozen_string_literal: true

require 'dotenv'
Dotenv.load('.env.test')

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

    c.filter_sensitive_data('<QUEUE_URL>') { ENV.fetch('QUEUE_URL', nil) }
    c.filter_sensitive_data('<QUEUE_ARN>') { ENV.fetch('QUEUE_ARN', nil) }
    c.filter_sensitive_data('<EXCHANGE_ARN>') { ENV.fetch('EXCHANGE_ARN', nil) }
    c.filter_sensitive_data('<ACCOUNT_NUMBER>') { ENV.fetch('ACCOUNT_NUMBER', nil) }
  end

  config.around(:each, :vcr_match_request_on) do |example|
    default = VCR.configuration.default_cassette_options[:match_requests_on]
    config = example.metadata[:vcr_match_request_on].each_with_object(default.dup) do |(match_type, enabled), result|
      enabled ? result.push(match_type) : result.delete(match_type)
    end.uniq

    VCR.configuration.default_cassette_options[:match_requests_on] = config
    example.call
  ensure
    VCR.configuration.default_cassette_options[:match_requests_on] = default
  end

  config.around(:each, :vcr) do |example|
    name = example.metadata[:vcr]
    VCR.use_cassette(name) { example.call }
  end
end
