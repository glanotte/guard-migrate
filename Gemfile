source "https://rubygems.org"

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
  gem 'rspec', '~> 2.11.0'
  gem 'files', '~> 0.2.1'

  # doh! not all ruby 1.9s have simplecov :(
  platform :mri_19 do
    gem 'simplecov', '~> 0.6.4', :group => :test, :require => false
  end

end

group :development do
  gem 'guard-rspec', '~> 1.2.1'
end
