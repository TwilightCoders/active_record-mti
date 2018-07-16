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

  rails_versions = ['>= 4', '< 6']
  spec.required_ruby_version = '>= 2.3'

  spec.add_runtime_dependency 'activerecord', rails_versions
  spec.add_runtime_dependency 'pg', '~> 0'
  spec.add_runtime_dependency 'active_registry', '~> 0.1'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rspec', '~> 3.7'
  spec.add_development_dependency 'combustion', '~> 0.7'
  spec.add_development_dependency 'pry-byebug', '~> 3'
  spec.add_development_dependency 'rake', '~> 12.0'
end
