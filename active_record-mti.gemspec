
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_record/mti/version'

Gem::Specification.new do |spec|
  spec.name          = 'active_record-mti'
  spec.version       = ActiveRecord::MTI::VERSION
  spec.authors       = ['Dale Stevens']
  spec.email         = ['dale@twilightcoders.net']

  spec.summary       = 'Multi Table Inheritance for PostgreSQL in Rails'
  spec.description   = "Gives ActiveRecord support for PostgreSQL's native inherited tables"
  spec.homepage      = 'https://github.com/twilightcoders/active_record-mti'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0")
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib', 'spec']

  rails_versions = ['>= 4', '< 6']
  spec.required_ruby_version = '>= 2.3'

  spec.add_runtime_dependency 'activerecord', rails_versions
  spec.add_runtime_dependency 'pg', '~> 0'
  spec.add_runtime_dependency 'registry', '~> 0.1.0'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rspec', '~> 3.7'
  spec.add_development_dependency 'combustion', '~> 0.7'
  spec.add_development_dependency 'pry-byebug', '~> 3'
  spec.add_development_dependency 'rake', '~> 12.0'
end
