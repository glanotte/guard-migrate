require 'guard'
require 'guard/guard'

module Guard
  class Migrate < Guard
    autoload :Notify, 'guard/migrate/notify'
    autoload :Migration, 'guard/migrate/migration'
    attr_reader :seed, :rails_env

    def initialize(watchers=[], options={})
      super

      @bundler = true unless options[:bundler] == false
      @cmd = options[:cmd].to_s unless options[:cmd].to_s.empty?
      @reset = true if options[:reset] == true
      @test_clone = options[:test_clone]
      @run_on_start = true if options[:run_on_start] == true
      @rails_env = options[:rails_env]
      @seed = options[:seed]
    end

    def bundler?
      !!@bundler && File.exist?("#{Dir.pwd}/Gemfile")
    end

    def run_on_start?
      !!@run_on_start
    end

    def cmd?
      !!@cmd
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
    def run_on_modifications(paths)
      if paths.any?{|path| path.match(%r{^db/migrate/(\d+).+\.rb})} || reset?
        migrations = paths.map {|path| Migration.new(path)}
        migrate(migrations)
      elsif paths.any?{|path| path.match(%r{^db/seeds\.rb$})}
        seed_only
      end
    end

    def migrate(migrations = [])
      return if !reset? && migrations.empty?
      if reset?
        UI.info "Running #{rake_string}"
        result = system(rake_string)
        result &&= "reset"
      else
        result = run_all_migrations(migrations)
      end

      Notify.new(result).notify
    end

    def seed_only
      UI.info "Running #{seed_only_string}"
      result = system(seed_only_string)
      result &&= "seed"
      Notify.new(result).notify
    end

    def run_redo?(version)
      !reset? && version && !version.empty?
    end

    def rake_string(version = nil)
      [
        bundler_command,
        custom_command,
        rake_command,
        migrate_string(version),
        seed_string,
        clone_string,
        rails_env_string
      ].compact.join(" ")
    end

    def seed_only_string
      [
        bundler_command,
        custom_command,
        rake_command,
        seed_string,
        clone_string,
        rails_env_string
      ].compact.join(" ")
    end

    private

    def run_all_migrations(migrations)
      result = nil
      migrations.each do |migration|
        if migration.valid?
          UI.info "Running #{rake_string(migration.version)}"
          result = system rake_string(migration.version)
          break unless result
        else
          UI.info "Skip empty migration - #{migration.version}"
        end
      end

      result
    end

    def rake_command
      "rake" unless custom_command.to_s.match(/rake/)
    end

    def bundler_command
      "bundle exec" if bundler?
    end

    def custom_command
      "#{@cmd.strip}" if cmd?
    end

    def rails_env_string
      "RAILS_ENV=#{rails_env}" if rails_env
    end

    def clone_string
      if test_clone? and !custom_command.to_s.match(/db:test:clone/)
        "db:test:clone"
      end
    end

    def seed_string
      "db:seed" if @seed
    end

    def migrate_string(version)
      if !custom_command.to_s.match(/db:migrate/)
        string = "db:migrate"
        string += ":reset" if reset?
        string += ":redo VERSION=#{version}" if run_redo?(version)
        string
      end
    end

  end
end

