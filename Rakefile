require 'bundler'
Bundler::GemHelper.install_tasks

default_tasks = []

require 'rspec/core/rake_task'
default_tasks << RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = (ENV['CI'] == 'true')
end

task default: :spec

if ENV['CI'] != 'true'
  require 'rubocop/rake_task'
  default_tasks << RuboCop::RakeTask.new(:rubocop)
end

task default: default_tasks.map(&:name)
