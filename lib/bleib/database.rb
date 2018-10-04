module Bleib
  class Database
    def initialize(configuration)
      @configuration = configuration
    end

    def establish_connection(&block)
      while database_down?
        sleep configuration.check_database_interval
      end

      begin
        yield if block_given?
      ensure
        # Nobody else shall use our single-connection pool.
        remove_connection
      end
    end

    private

    def database_down?
      begin
        # Adopted from the default OpenShift readiness check for postgresql.
        ActiveRecord::Base.establish_connection(configuration.database_connection)
        ActiveRecord::Base.connection.execute("SELECT 1;")

        false
      rescue PG::ConnectionBad
        # On stopped database:
        #   PG::ConnectionBad: could not connect to server: Connection refused
        #   Is the server running on host "127.0.0.1" and accepting
        #   TCP/IP connections on port 5432?
        # On wrong/missing user:
        #   PG::ConnectionBad: FATAL:  password authentication failed for user "wrong"
        # On wrong password:
        #   PG::ConnectionBad: FATAL:  password authentication failed for user "user"

        true
      rescue ActiveRecord::NoDatabaseError
        # On missing database:
        #   ActiveRecord::NoDatabaseError: FATAL:  database "wrong" does not exist
        true
      end
    end

    def remove_connection
      ActiveRecord::Base.remove_connection
    end
  end
end
