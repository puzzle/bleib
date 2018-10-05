Gem::Specification.new do |s|
  s.name        = 'bleib'
  s.version     = '0.0.3'
  s.date        = '2018-10-04'
  s.summary     = 'Use a rake task to wait on database and migrations.'
  s.description = 'Intended for use in containerized setups where' \
                  'another component takes care of migrating the database.'
  s.authors     = ['Puzzle ITC']
  s.email       = 'raez@puzzle.ch'
  s.files       = ['lib/bleib.rb']
  s.metadata    = {
                    'source_code_uri'   => 'https://github.com/puzzle/bleib',
                    'documentation_uri' => 'https://github.com/puzzle/bleib'
                  }
  s.homepage    = 'http://rubygems.org/gems/bleib'
  s.license     = 'MIT'
end
