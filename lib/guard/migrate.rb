require 'guard'
require 'guard/guard'

module Guard
  class Migrate < Guard
    attr_reader :seed, :rails_env

    def initialize(watchers=[], options={})
      super
      
      @reset = true if options[:reset] == true
      @test_clone = true unless options[:test_clone] == false
      @run_on_start = true if options[:run_on_start] == true
      @rails_env = options[:rails_env]
      @seed = options[:seed]
    end

    def bundler?
      @bundler ||= File.exist?("#{Dir.pwd}/Gemfile")
    end

    def run_on_start?
      !!@run_on_start
    end

    def test_clone?
      !!@test_clone
    end

    def reset?
      !!@reset
    end

    # =================
    # = Guard methods =
    # =================

    # If one of those methods raise an exception, the Guard::GuardName instance
    # will be removed from the active guards.

    # Called once when Guard starts
    # Please override initialize method to init stuff
    def start
      migrate if run_on_start?
    end

    # Called on Ctrl-C signal (when Guard quits)
    def stop
      true
    end

    # Called on Ctrl-Z signal
    # This method should be mainly used for "reload" (really!) actions like reloading passenger/spork/bundler/...
    def reload
      migrate if run_on_start?
    end

    # Called on Ctrl-/ signal
    # This method should be principally used for long action like running all specs/tests/...
    def run_all
      migrate if run_on_start?
    end

    # Called on file(s) modifications
    def run_on_changes(paths)
      migrate(paths.map{|path| path.scan(%r{^db/migrate/(\d+).+\.rb}).flatten.first})
    end

    def migrate(paths = [])
      return if !reset? && paths.empty?
      system rake_string if reset?
      paths.each do |path|
        UI.info "Running #{rake_string(path)}"
        system rake_string(path)
      end
    end

    def run_redo?(path)
      !reset? && path && !path.empty?
    end

    def rake_string(path = nil)
      @rake_string = ''
      @rake_string += 'bundle exec ' if bundler?
      @rake_string += 'rake'
      @rake_string += ' db:migrate'
      @rake_string += ':reset' if reset?
      @rake_string += ":redo VERSION=#{path}" if run_redo?(path)
      @rake_string += " db:seed" if @seed
      @rake_string += ' db:test:clone' if test_clone?
      @rake_string += " RAILS_ENV=#{rails_env}" if rails_env
      @rake_string
    end
  end
end

