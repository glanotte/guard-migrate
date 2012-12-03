# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "guard/migrate/version"

Gem::Specification.new do |s|
  s.name        = "guard-migrate"
  s.version     = Guard::MigrateVersion::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Geoff Lanotte"]
  s.email       = ["geofflanotte@gmail.com"]
  s.homepage    = "http://rubygems.org/gems/guard-migrate"
  s.summary     = "Guard gem for rails migrations"
  s.description = "Guard::Migrate automatically runs your database migrations when needed"

  s.required_rubygems_version = '>= 1.3.6'
  s.rubyforge_project = "guard-migrate"

  s.add_dependency 'guard',   '>= 1.3.0'

  s.add_development_dependency 'rspec', '~> 2.11.0'
  s.add_development_dependency 'guard-rspec', '~> 1.2.1'

  s.files = Dir.glob('{lib}/**/*') + %w[LICENSE.txt README.rdoc]
  s.require_path = 'lib'
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.require_paths = ["lib"]

  s.rdoc_options = ["--charset=UTF-8", "--main=README.rdoc", "--exclude='(lib|test|spec)|(Gem|Guard|Rake)file'"]
end
