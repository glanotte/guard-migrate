source 'https://rubygems.org'

# Specify your gem's dependencies in guard-migrate.gemspec
gemspec

gem 'growl'
gem 'rake'

platforms :ruby do
  gem 'rb-fsevent', '>= 0.3.2'
end

platforms :rbx do
  gem 'rubysl', '~> 2.0'
end

group :test do
  gem 'rspec', '~> 2.14.1'
  gem 'files', '~> 0.3.1'
  gem 'simplecov', '~> 0.8.2', require: false
end

group :development do
  gem 'guard-rspec', '~> 4.2.5'
  gem 'pry'
  gem 'rubocop'
  gem 'transpec'
end
