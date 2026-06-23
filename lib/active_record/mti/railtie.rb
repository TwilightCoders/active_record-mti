require 'active_record/mti/core_extension'
require 'active_record/mti/connection_adapters/postgresql/schema_statements'
require 'active_record/mti/connection_adapters/postgresql/adapter'
require 'active_record/mti/schema_dumper'

module ActiveRecord
  module MTI
    class Railtie < Rails::Railtie
      initializer 'active_record-mti.load' do |_app|
        ActiveSupport.on_load(:active_record) do
          ::ActiveRecord::Base.prepend(::ActiveRecord::MTI::CoreExtension)

          ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(ConnectionAdapters::PostgreSQL::Adapter)
          ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(ConnectionAdapters::PostgreSQL::SchemaStatements)
          ::ActiveRecord::SchemaDumper.prepend(SchemaDumper)

          # Prepend the MTI relation behavior once, globally. build_mti is a no-op unless
          # the relation's klass is MTI (klass.tableoid?), so this is safe for every model
          # and avoids the order-dependent fragility of prepending into each class's
          # relation_delegate_cache (delegates created lazily after that point would
          # otherwise miss the patch and silently drop tableoid projection/discrimination).
          ::ActiveRecord::Relation.prepend(::ActiveRecord::MTI::Relation)
        end
      end
    end
  end
end
