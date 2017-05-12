require 'active_record/mti/version'
require 'active_record'
require 'active_record/connection_handling'
require 'active_record/mti/schema_dumper'
require 'active_record/mti/inheritance'
require 'active_record/mti/model_schema'
require 'active_record/mti/query_methods'
require 'active_record/mti/calculations'
require 'active_record/mti/connection_adapters/postgresql/schema_statements'

require 'active_record/mti/railtie' if defined?(Rails::Railtie)

module ActiveRecord
  module MTI

    def self.root
      @root ||= Pathname.new(File.expand_path('../../', File.dirname(__FILE__)))
    end

    def self.load
      ::ActiveRecord::Base.send                                  :include, Inheritance
      ::ActiveRecord::Base.send                                  :include, ModelSchema
      ::ActiveRecord::Relation.send                              :include, QueryMethods
      ::ActiveRecord::Relation.send                              :include, Calculations
      ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.send :include, ConnectionAdapters::PostgreSQL::SchemaStatements
      ::ActiveRecord::SchemaDumper.send                          :include, SchemaDumper
    end
  end
end
