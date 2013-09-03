if RUBY_VERSION.match(/^1\.9\.\d?$/)
  begin
    require 'simplecov'
    SimpleCov.start 'rails'
  rescue LoadError
    # not finding simplecov is no reason to fail!
  end
end

require 'rspec'
require 'guard/migrate'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.color_enabled = true
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.before(:each) do
    ENV["GUARD_ENV"] = 'test'
  end

  config.after(:each) do
    ENV["GUARD_ENV"] = nil
  end

  config.include MigrationFactory
end
