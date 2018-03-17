# === boot ===

begin
  require "bundler/setup"
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

# === application ===

require "rails"
require "combustion"
# require "active_record/railtie"

# Bundler.require :default, Rails.env

# === Rakefile ===

task :environment do
  Combustion::Application.path = 'spec/support/rails'
  Combustion::Application.initialize!

  # # Reset migrations paths so we can keep the migrations in the project root,
  # # not the Rails root
  # migrations_paths = ["db/migrate"]
  # ActiveRecord::Tasks::DatabaseTasks.migrations_paths = migrations_paths
  # ActiveRecord::Migrator.migrations_paths = migrations_paths
end

require "rspec/core/rake_task"

Combustion::Application.load_tasks

task(:default).clear
task(:spec).clear

RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = false
end

task default: [:spec]
