module Bleib
  # Finds out if all migrations are up.
  #
  # Knows how to handle multitenancy with Apartment, if used.
  # Checks also migrations with Wagons, if used.
  class Migrations
    def initialize(configuration)
      @configuration = configuration
    end

    def wait_until_done
      logger.info('Waiting for migrations')
      logger.info('Also checking apartment tenants:' + " #{apartment_gem? ? 'yes' : 'no'}")
      logger.info('Also checking wagon migrations:' + " #{wagons_gem? ? 'yes' : 'no'}")

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

    def wagons_gem?
      defined?(Wagons)
    end

    def check_migrations!
      check_wagon_migrations! if wagons_gem?

      # https://apidock.com/rails/v7.1.3.4/ActiveRecord/Migration/check_pending
      if Rails::VERSION::MAJOR < 7 || (Rails::VERSION::MAJOR == 7 && Rails::VERSION::MINOR.zero?)
        ActiveRecord::Migration.check_pending!
      else
        ActiveRecord::Migration.check_all_pending!
      end
    end

    def check_wagon_migrations!
      paths = Wagons.all.flat_map(&:migrations_paths)
      context = ActiveRecord::MigrationContext.new(paths, ActiveRecord::SchemaMigration)

      # we do not need the correct output, just the right exception
      # in this case, the output only considers the main-app migration, not the ones in wagons
      raise ActiveRecord::PendingMigrationError if context.needs_migration?
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
