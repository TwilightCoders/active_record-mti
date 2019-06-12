require_relative 'lib/active_record/mti/version'

Gem::Specification.new do |spec|
  spec.name          = 'active_record-mti'
  spec.version       = ActiveRecord::MTI::VERSION
  spec.authors       = ['Dale Stevens']
  spec.email         = ['dale@twilightcoders.net']

  spec.summary       = 'Multi Table Inheritance for PostgreSQL in Rails'
  spec.description   = "Gives ActiveRecord support for PostgreSQL's native inherited tables"
  spec.homepage      = 'https://github.com/twilightcoders/active_record-mti'
  spec.license       = 'MIT'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.files         = Dir['CHANGELOG.md', 'README.md', 'LICENSE', 'lib/**/*']
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib', 'spec']

  rails_versions = ['>= 4.2']
  spec.required_ruby_version = '>= 2.3'

  spec.add_runtime_dependency 'activerecord', rails_versions
  spec.add_runtime_dependency 'pg'
  spec.add_runtime_dependency 'registry', '~> 0.2.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'combustion'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'simplecov'
end
