# frozen_string_literal: true

namespace :bleib do
  desc 'Waits for database access'
  task wait_for_database: :environment do
    configuration = Bleib::Configuration.from_environment
    Bleib::Database.new(configuration).wait_for_connection
  end

  desc 'Waits for database access and migrations'
  task wait_for_migrations: :wait_for_database do
    configuration = Bleib::Configuration.from_environment

    Bleib::Migrations.new(configuration).wait_until_done
  end
end
