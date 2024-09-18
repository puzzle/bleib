module Bleib
  # Finds out if all migrations are up.
  #
  # Knows how to handle multitenancy with Apartment, if used.
  class Migrations
    def initialize(configuration)
      @configuration = configuration
    end

    def wait_until_done
      logger.info('Waiting for migrations' \
                   ' (Also checking apartment tenants:' \
                   " #{apartment_gem? ? 'yes' : 'no'})")

      wait while pending_migrations?

      logger.info('All migrations are up')
    end

    private

    def wait
      duration = @configuration.check_migrations_interval

      logger.debug "Waiting for #{@configuration.check_migrations_interval} seconds"

      sleep(duration)
    end

    def pending_migrations?
      logger.debug('Checking migrations')

      if apartment_gem?
        in_all_tenant_contexts { check_migrations! }
      else
        check_migrations!
      end

      logger.debug('Migrations check succeeded.')

      false
    rescue ActiveRecord::PendingMigrationError
      logger.debug('Migrations pending, check failed')

      true
    end

    def apartment_gem?
      defined?(Apartment::Tenant)
    end

    def check_migrations!
      ActiveRecord::Migration.check_pending!
    end

    def in_all_tenant_contexts(&block)
      tenants = [ENV.fetch('BLEIB_DEFAULT_TENANT', 'public')] +
                Apartment.tenant_names

      tenants.uniq.each do |tenant|
        Apartment::Tenant.switch(tenant, &block)
      end
    end

    def logger
      @configuration.logger
    end
  end
end
