require 'active_record/mti/schema_dumper'
require 'active_record/mti/inheritance'
require 'active_record/mti/query_methods'
require 'active_record/mti/calculations'
require 'active_record/mti/connection_adapters/postgresql/schema_statements'

module ActiveRecord
  module MTI
    class Railtie < Rails::Railtie
      initializer 'active_record-mti.inheritance.initialization' do |_app|
        ::ActiveRecord::Base.send :include, Inheritance
        ::ActiveRecord::Relation.send :include, QueryMethods
        ::ActiveRecord::Relation.send :include, ActiveRecord::MTI::Calculations

        ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.send :include, ConnectionAdapters::PostgreSQL::SchemaStatements
        ::ActiveRecord::SchemaDumper.send :include, ActiveRecord::MTI::SchemaDumper
      end
    end
  end
end

