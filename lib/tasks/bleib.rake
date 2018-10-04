namespace :bleib do
  desc 'Waits for database access and migrations'
  task :wait_for_migrations => [:environment] do
    puts "Hello."
  end
end
