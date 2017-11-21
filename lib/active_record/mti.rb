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

    # Rails likes to make breaking changes in it's minor versions (like 4.1 - 4.2) :P
    cattr_reader :oid_class do
      [
        '::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::Integer', # 4.0, 4.1
        '::ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Integer', # 4.2
        '::ActiveRecord::Type::Integer' # 5.0, 5.1
      ].find { |klass|
        Object.const_defined?(klass)
      }.constantize
    end

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
      ::ActiveRecord::Relation.send                              :prepend, QueryMethods
      ::ActiveRecord::Relation.send                              :prepend, Calculations
      ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.send :prepend, ConnectionAdapters::PostgreSQL::Adapter
      ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.send :prepend, ConnectionAdapters::PostgreSQL::SchemaStatements
      ::ActiveRecord::SchemaDumper.send                          :prepend, SchemaDumper
    end

    def self.testify(value)
      value == true || value == 't' || value == 1 || value == '1'
    end

  end
end
