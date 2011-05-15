require 'guard'
require 'guard/guard'

module Guard
  class Migrate < Guard
    def initialize(watchers=[], options={})
      super
      
      @reset = true unless options[:reset] == false
      @test_clone = true unless options[:test_clone] == false
      @run_on_start = true if options[:run_on_start] == true
      @rails_env = options[:rails_env]
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

    def rails_env
      @rails_env
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
      self.migrate
    end

    def migrate
      system self.rake_string
    end

    def rake_string
      @rake_string = 'rake'
      @rake_string += ' db:migrate'
      @rake_string += ':reset' if self.reset?
      @rake_string += ' db:test:clone' if self.test_clone?
      @rake_string += " RAILS_ENV=#{self.rails_env}" if self.rails_env
      @rake_string
    end

  end
end

