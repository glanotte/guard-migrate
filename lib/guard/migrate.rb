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
      self.migrate if self.run_on_start?
    end

    # Called on Ctrl-C signal (when Guard quits)
    def stop
      true
    end

    # Called on Ctrl-Z signal
    # This method should be mainly used for "reload" (really!) actions like reloading passenger/spork/bundler/...
    def reload
      self.migrate if self.run_on_start?
    end

    # Called on Ctrl-/ signal
    # This method should be principally used for long action like running all specs/tests/...
    def run_all
      self.migrate if self.run_on_start?
    end

    # Called on file(s) modifications
    def run_on_change(paths)
      self.migrate(paths.map{|path| path.scan(%r{^db/migrate/(\d+).+\.rb}).flatten.first})
    end

    def migrate(paths = [])
      return if !self.reset? && paths.empty?
      system self.rake_string if self.reset?
      paths.each do |path|
        UI.info "Running #{self.rake_string(path)}"
        system self.rake_string(path)
      end
    end

    def rake_string(path = nil)
      @rake_string = ''
      @rake_string += 'bundle exec ' if self.bundler?
      @rake_string += 'rake'
      @rake_string += ' db:migrate'
      @rake_string += ':reset' if self.reset?
      @rake_string += ":redo VERSION=#{path}" if !self.reset? && path && !path.empty?
      @rake_string += ' db:test:clone' if self.test_clone?
      @rake_string += " RAILS_ENV=#{self.rails_env}" if self.rails_env
      @rake_string += " db:seed" if @seed
      @rake_string
    end
  end
end

