ENV['RAILS_ENV'] = 'test'

require 'logger'
require 'database_cleaner'
require 'combustion'

require 'pry'

require 'simplecov'
SimpleCov.start do
  add_filter 'spec'
end

Combustion.path = 'spec/support/rails'

# Rails 5.2 + newer Rack raises NoMethodError on middleware `operations`.
# We only need :active_record, so suppress the middleware stack build.
if defined?(ActionDispatch::MiddlewareStack) && !ActionDispatch::MiddlewareStack.method_defined?(:operations)
  ActionDispatch::MiddlewareStack.class_eval do
    def operations
      @operations ||= []
    end
  end
end

Combustion.initialize! :active_record

RSpec.configure do |config|
  config.order = 'random'

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end

RSpec::Matchers.define :match_sql do |expected_sql|
  expected_sql.squish!.gsub!(/([\.\*\(\)\/])/, '\\\\\1')

  match do |actual_sql|
    actual_sql.match(Regexp.new(expected_sql))
  end

  failure_message do |actual_sql|
    "expected:\n#{actual_sql.indent(2)}\nto match:\n#{expected_sql.indent(2)}"
  end
end
