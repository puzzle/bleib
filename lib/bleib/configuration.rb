# frozen_string_literal: true

require 'active_record/database_configurations'

module Bleib
  class Configuration
    class UnsupportedAdapterException < Exception; end
    class DatabaseYmlNotFoundException < Exception; end

    attr_reader :database, :check_database_interval, :check_migrations_interval

    DEFAULT_CHECK_DATABASE_INTERVAL = 5 # Seconds
    DEFAULT_CHECK_MIGRATIONS_INTERVAL = 5 # Seconds
    DEFAULT_DATABASE_YML_PATH = 'config/database'

    SUPPORTED_ADAPTERS = %w(postgresql postgis mysql2)

    POOL_KEYS = %w(pool max_connections min_connections).freeze

    def self.from_environment
      check_database_interval = interval_or_default(
        ENV['BLEIB_CHECK_DATABASE_INTERVAL'],
        DEFAULT_CHECK_DATABASE_INTERVAL
      )
      check_migrations_interval = interval_or_default(
        ENV['BLEIB_CHECK_MIGRATIONS_INTERVAL'],
        DEFAULT_CHECK_MIGRATIONS_INTERVAL
      )

      database_yml_path = ENV['BLEIB_DATABASE_YML_PATH']
      database_yml_path ||= File.expand_path('config/database.yml')
      ensure_database_yml!(database_yml_path)

      rails_env = ENV['RAILS_ENV'] || 'development'

      new(
        rails_database(database_yml_path, rails_env),
        check_database_interval: check_database_interval.to_i,
        check_migrations_interval: check_migrations_interval.to_i
      )
    end

    def initialize(database_configuration,
                   check_database_interval: DEFAULT_CHECK_DATABASE_INTERVAL,
                   check_migrations_interval: DEFAULT_CHECK_MIGRATIONS_INTERVAL)
      # To be 100% sure which connection the
      # active record pool creates, returns or removes.
      @database = database_configuration
                  .reject { |key, _| POOL_KEYS.include?(key.to_s) }
                  .merge(single_connection_key => 1)

      @check_database_interval = check_database_interval
      @check_migrations_interval = check_migrations_interval

      check!
    end

    def logger
      return @logger unless @logger.nil?

      @logger = Logger.new(STDOUT)
      @logger.level = if ENV['BLEIB_LOG_LEVEL'] == 'debug'
                        Logger::DEBUG
                      else
                        Logger::INFO
                      end
      @logger
    end

    private

    def single_connection_key
      # Rails >= 8.1 renamed `pool` to `max_connections` and aborts when both are set.
      hash_config = ActiveRecord::DatabaseConfigurations::HashConfig
      return 'max_connections' if hash_config.method_defined?(:min_connections)

      'pool'
    end

    def self.interval_or_default(string, default)
      given = string.to_i
      given <= 0 ? default : given
    end

    def self.ensure_database_yml!(path)
      return if File.exist?(path)

      fail DatabaseYmlNotFoundException,
           'database.yml not found, set or fix' \
           ' BLEIB_DATABASE_YML_PATH or execute me' \
           ' from the rails root.'
    end

    def self.rails_database(database_yml_path, rails_env)
      contents = File.read(database_yml_path)
      config = load_yaml(ERB.new(contents).result)
      config[rails_env]
    end

    # Psych 4 Patch: https://github.com/rails/rails/commit/179d0a1f474ada02e0030ac3bd062fc653765dbe
    def self.load_yaml(content)
      begin
        YAML.load(content, aliases: true)
      rescue ArgumentError
        YAML.load(content)
      end
    end

    def check!
      # We should add clean rescue statements to
      # `Bleib::Database#database_down?`to support
      # other adapters.
      return if SUPPORTED_ADAPTERS.include?(@database['adapter'])

      fail UnsupportedAdapterException,
           "Unknown database adapter #{@database['adapter']}"
    end
  end
end
