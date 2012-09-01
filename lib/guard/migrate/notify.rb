module Guard
  class Migrate
    class Notify
      def initialize(result)
        @result = result
      end

      def message
        case @result
        when "reset" then "The database has been reset"
        when "seed" then "The database has been seeded"
        when true then "Migrations have been applied successfully"
        else "There was an error running migrations"
        end
      end

      def image
        @result ? :success : :failure
      end

      def notify
        ::Guard::Notifier.notify(message, :title => "Database Migrations", :image => image)
      end
    end
  end
end
