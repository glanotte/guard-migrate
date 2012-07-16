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
      if paths.any?{|path| path.match(%r{^db/migrate/(\d+).+\.rb})}
        migrate(paths.map{|path| path.scan(%r{^db/migrate/(\d+).+\.rb}).flatten.first})
      elsif paths.any?{|path| path.match(%r{^db/seeds\.rb$})}
        seed_only
      end
    end

    def migrate(paths = [])
      return if !reset? && paths.empty?
      system rake_string if reset?
      paths.each do |path|
        UI.info "Running #{rake_string(path)}"
        system rake_string(path)
      end
    end

    def seed_only
      UI.info "Running #{seed_only_string}"
      system seed_only_string
    end

    def run_redo?(path)
      !reset? && path && !path.empty?
    end

    def rake_string(path = nil)
      rake_string = rake_command
      rake_string += migrate_string(path)
      rake_string += seed_string
      rake_string += clone_string
      rake_string += rails_env_string
      rake_string
    end

    def seed_only_string
      seed_only = rake_command
      seed_only += seed_string
      seed_only += clone_string
      seed_only
    end

    private

    def rake_command
      command = ''
      command += 'bundle exec ' if bundler?
      command += 'rake'
      command
    end

    def rails_env_string
      return "" unless rails_env
      " RAILS_ENV=#{rails_env}"
    end

    def clone_string
      return '' unless test_clone?
      ' db:test:clone'
    end

    def seed_string
      return '' unless @seed
      " db:seed"
    end

    def migrate_string(path)
      string = ' db:migrate'
      string += ':reset' if reset?
      string += ":redo VERSION=#{path}" if run_redo?(path)
      string
    end

  end
end

