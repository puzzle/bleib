module Bleib
  class Configuration
    class UnsupportedAdapterException < Exception; end

    attr_reader :database, :check_database_interval, :check_migrations_interval

    DEFAULT_CHECK_DATABASE_INTERVAL = 5_000
    DEFAULT_CHECK_MIGRATIONS_INTERVAL = 5_000

    def self.from_environment
      check_database_interval = ENV['BLEIB_CHECK_DATABASE_INTERVAL']
      check_database_interval ||= DEFAULT_CHECK_DATABASE_INTERVAL
      check_migrations_interval = ENV['BLEIB_CHECK_MIGRATIONS_INTERVAL']
      check_migrations_interval ||= DEFAULT_CHECK_MIGRATIONS_INTERVAL

      new(
        rails_database,
        check_database_interval: check_database_interval,
        check_migrations_interval: check_migrations_interval
      )
    end

    def initialize(database_configuration,
                   check_database_interval: DEFAULT_CHECK_DATABASE_INTERVAL,
                   check_migrations_interval: DEFAULT_CHECK_MIGRATIONS_INTERVAL)
      # To be 100% sure which connection the
      # active record pool creates, returns or removes.
      only_one_connection = { 'pool' => 1 }

      @database = database_configuration.merge(only_one_connection)

      @check_database_interval = check_database_interval
      @check_migrations_interval = check_migrations_interval

      check!
    end

    private

    def check!
      # We should add clean rescue statements to `Bleib::Database#database_down?`
      # To support other adapters.
      if @database['adapter'] != 'postgresql'
        fail UnsupportedAdapterException,
             "Unknown database adapter #{@database['adapter']}"
      end
    end

    def rails_database
      Rails.configuration.database_configuration[Rails.env]
    end
  end
end
