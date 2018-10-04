class Bleib::Railtie < Rails::Railtie
  rake_tasks do
    load 'tasks/bleib.rake'
  end
end
