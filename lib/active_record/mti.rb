require 'active_record/mti/version'
require 'active_record/mti/railtie'
require 'active_record'
require 'active_record/connection_handling'
require 'active_record/mti/schema_dumper'
require 'active_record/mti/inheritance'
require 'active_record/mti/query_methods'
require 'active_record/mti/calculations'
require 'active_record/mti/connection_adapters/postgresql/schema_statements'

module ActiveRecord
  module MTI
    # Your code goes here...
    def self.load
      ::ActiveRecord::Base.send :include, Inheritance
      ::ActiveRecord::Relation.send :include, QueryMethods
      ::ActiveRecord::Relation.send :include, ActiveRecord::MTI::Calculations

      ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.send :include, ConnectionAdapters::PostgreSQL::SchemaStatements
      ::ActiveRecord::SchemaDumper.send :include, ActiveRecord::MTI::SchemaDumper
    end
  end
end
