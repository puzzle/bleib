require_relative 'lib/bleib/version'

Gem::Specification.new do |s|
  s.name        = 'bleib'
  s.version     = Bleib::VERSION
  s.date        = '2024-09-18'
  s.summary     = 'Use a rake task to wait on database and migrations.'
  s.description = 'Intended for use in containerized setups where ' \
                  'another component takes care of migrating the database.'
  s.authors     = ['Puzzle ITC']
  s.email       = 'viehweger@puzzle.ch'
  s.files       = Dir['lib/**/*']
  s.metadata    = {
    'source_code_uri' => 'https://github.com/puzzle/bleib',
    'documentation_uri' => 'https://github.com/puzzle/bleib'
  }
  s.homepage    = 'https://rubygems.org/gems/bleib'
  s.license     = 'MIT'
end
