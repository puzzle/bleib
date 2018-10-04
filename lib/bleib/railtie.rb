module Bleib
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/bleib.rake'
    end
  end
end
