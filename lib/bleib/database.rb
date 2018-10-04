module Bleib
  # Finds out if a database is running and accessible.
  #
  # Does so by using ActiveRecord without a booted rails
  # environment (because a non-accessible database can
  # cause the bootup to fail).
  class Database
    def initialize(configuration)
      @configuration = configuration
    end

    def wait_for_connection
      logger.info('Waiting for connection to database')

      wait while database_down?

      logger.info('Connection to database established')

      # Nobody else shall use our single-connection pool.
      remove_connection
    end

    private

    def wait
      duration = @configuration.check_database_interval

      logger.debug "Waiting for #{duration} seconds"

      sleep(duration)
    end

    def database_down?
      logger.debug('Checking database')

      # Adopted from the default OpenShift readiness check for postgresql.
      ActiveRecord::Base.establish_connection(@configuration.database)
      ActiveRecord::Base.connection.execute('SELECT 1;')

      logger.debug('Database check succeeded')

      false
    rescue PG::ConnectionBad => e
      # On stopped database:
      #   PG::ConnectionBad: could not connect to server: Connection refused
      #   Is the server running on host "127.0.0.1" and accepting
      #   TCP/IP connections on port 5432?
      # On wrong/missing user:
      #   PG::ConnectionBad: FATAL:  password authentication failed for user "wrong"
      # On wrong password:
      #   PG::ConnectionBad: FATAL:  password authentication failed for user "user"

      logger.debug("Database check failed: #{e}")

      true
    rescue ActiveRecord::NoDatabaseError
      # On missing database:
      #   ActiveRecord::NoDatabaseError: FATAL:  database "wrong" does not exist

      logger.debug("Database check failed: #{e}")

      true
    end

    def remove_connection
      ActiveRecord::Base.remove_connection
    end

    def logger
      @configuration.logger
    end
  end
end
