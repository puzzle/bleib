namespace :bleib do
  desc 'Waits for database access and migrations'
  task wait_for_migrations: [:environment] do
    configuration = Bleib::Configuration.from_environment

    Bleib::Database.new(configuration).establish_connection do
      Bleib::Migrations.new(configuration).wait_until_done
    end
  end
end
