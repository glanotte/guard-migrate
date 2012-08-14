source "http://rubygems.org"

# Specify your gem's dependencies in guard-migrate.gemspec
gemspec

gem 'growl'
gem 'rake'

platforms :ruby do
  gem 'rb-fsevent', '>= 0.3.2'
end

group :test do
  gem 'files', '~> 0.2.1'

  platform :ruby_19 do
    gem 'simplecov', '~> 0.6.4', :group => :test, :require => false
  end

end
