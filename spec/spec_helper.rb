if RUBY_VERSION.to_f == 1.9
  begin
    require 'simplecov'
    SimpleCov.start 'rails'
  rescue LoadError
    # not finding simplecov is no reason to fail!
  end
end

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run focus: (ENV['CI'] != 'true')
  config.run_all_when_everything_filtered = true

  config.disable_monkey_patching!

  # config.warnings = true

  config.default_formatter = 'doc' if config.files_to_run.one?

  # config.profile_examples = 10

  config.order = :random

  Kernel.srand config.seed

  config.include MigrationFactory
end
