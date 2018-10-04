module Bleib
  class Migrations
    def initialize(configuration)
      @configuration = configuration
    end

    def wait_until_done
      wait while pending_migrations?
    end

    private

    def wait
      sleep(@configuration.check_migrations_interval)
    end

    def pending_migrations?
      if apartment_gem?
        in_all_tenant_contexts { check_migrations! }
      else
        check_migrations!
      end
      false
    rescue ActiveRecord::PendingMigrationError
      true
    end

    def apartment_gem?
      defined?(Apartment::Tenant)
    end

    def check_migrations!
      ActiveRecord::Migration.check_pending!
    end

    def in_all_tenant_contexts
      tenants = ['public']
      Apartment::Tenant.each { |tenant| tenants << tenant }

      tenants.each do |tenant|
        Apartment::Tenant.switch(tenant) do
          yield
        end
      end
    end
  end
end
