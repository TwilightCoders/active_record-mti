# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_record/mti/version'

Gem::Specification.new do |spec|
  spec.name          = "active_record-mti"
  spec.version       = ActiveRecord::MTI::VERSION
  spec.authors       = ["Dale Stevens"]
  spec.email         = ["dale@twilightcoders.net"]
  spec.summary       = %q{Multi Table Inheritance for PostgreSQL in Rails}
  spec.description   = %q{Allows use of native inherited tables in PostgreSQL}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency 'rake', '~> 0'
  spec.add_runtime_dependency 'rails', '~> 4.1', '> 4.1'
  spec.add_runtime_dependency 'pg', '~> 0'

end
