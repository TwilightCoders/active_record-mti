require 'active_record/mti/core_extension'
require 'active_record/mti/child/model_schema'
require 'active_record/mti/parent/query_methods'
require 'active_record/mti/parent/calculations'
require 'active_record/mti/connection_adapters/postgresql/schema_statements'
require 'active_record/mti/connection_adapters/postgresql/adapter'
require 'active_record/mti/schema_dumper'

module ActiveRecord
  module MTI
    class Railtie < Rails::Railtie
      initializer 'active_record-mti.load' do |_app|
        ActiveRecord::MTI.logger.debug 'active_record-mti.load'
        ActiveSupport.on_load(:active_record) do
          ::ActiveRecord::Base.include(::ActiveRecord::MTI::CoreExtension)

          ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(ConnectionAdapters::PostgreSQL::Adapter)
          ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(ConnectionAdapters::PostgreSQL::SchemaStatements)
          ::ActiveRecord::SchemaDumper.prepend(SchemaDumper)
        end
      end
    end
  end
end
