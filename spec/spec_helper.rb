require 'simplecov'
require 'bundler/setup'
require 'fakeredis'
require 'pry'

# Set default REDIS_URL environment variable
ENV['REDIS_URL'] = 'oie'

SimpleCov.start if ENV['COVERAGE'] == 'true'

require 'upperkut'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
