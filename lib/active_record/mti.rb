require 'active_record/mti/version'
require 'active_record'
require 'active_record/connection_handling'
require 'active_record/mti/schema_dumper'
require 'active_record/mti/inheritance'
require 'active_record/mti/model_schema'
require 'active_record/mti/query_methods'
require 'active_record/mti/calculations'
require 'active_record/mti/connection_adapters/postgresql/schema_statements'
require 'active_record/mti/connection_adapters/postgresql/adapter'

require 'active_record/mti/railtie' if defined?(Rails::Railtie)

module ActiveRecord
  module MTI

    class << self
      attr_writer :logger

      def logger
        @logger ||= Logger.new($stdout).tap do |log|
          log.progname = self.name
          log.level = Logger::INFO
        end
      end
    end

    def self.root
      @root ||= Pathname.new(File.expand_path('../../', File.dirname(__FILE__)))
    end

    def self.load
      ::ActiveRecord::Base.send                                  :include, Inheritance
      ::ActiveRecord::Base.send                                  :include, ModelSchema
      ::ActiveRecord::Relation.send                              :include, QueryMethods
      ::ActiveRecord::Relation.send                              :include, Calculations
      ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.send :prepend, ConnectionAdapters::PostgreSQL::Adapter
      ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.send :include, ConnectionAdapters::PostgreSQL::SchemaStatements
      ::ActiveRecord::SchemaDumper.send                          :include, SchemaDumper
    end
  end
end
