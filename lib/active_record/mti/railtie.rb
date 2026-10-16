module ActiveRecord
  module MTI
    class Railtie < Rails::Railtie
      initializer 'active_record-mti.load' do |_app|
        ActiveSupport.on_load(:active_record) do
          require 'active_record/mti/core_extension'
          require 'active_record/mti/schema_dumper'

          ::ActiveRecord::Base.prepend(::ActiveRecord::MTI::CoreExtension)
          ::ActiveRecord::SchemaDumper.prepend(::ActiveRecord::MTI::SchemaDumper)

          # Prepend the MTI relation behaviour once, globally. build_mti is a no-op unless the
          # relation's klass is MTI (klass.tableoid?), so this is safe for every model, and it
          # avoids the order-dependent fragility of prepending into each class's
          # relation_delegate_cache (a relation built before its class resolved mti_table would
          # silently drop the tableoid projection and with it discrimination).
          ::ActiveRecord::Relation.prepend(::ActiveRecord::MTI::Relation)

          # Rails 7.1+ lazy-loads connection adapters, so PostgreSQLAdapter may
          # not be defined when :active_record loads (e.g. when another gem's
          # railtie boots first). Prepend immediately if it's already present;
          # otherwise the adapter load hook below handles it. That hook doesn't
          # exist before 7.1, so there the adapter is loaded now.
          if defined?(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) || !::ActiveRecord::MTI::Railtie.adapter_load_hook?
            require 'active_record/connection_adapters/postgresql_adapter'
            ::ActiveRecord::MTI::Railtie.patch_postgresql_adapter!(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
          end
        end

        # Fires when PostgreSQLAdapter loads on Rails 7.1+. Re-prepending the
        # same module is a no-op, so this is safe even if both paths run.
        ActiveSupport.on_load(:active_record_postgresqladapter) do
          ::ActiveRecord::MTI::Railtie.patch_postgresql_adapter!(self)
        end
      end

      # ActiveRecord 7.1 added the :active_record_postgresqladapter load hook.
      def self.adapter_load_hook?
        ::ActiveRecord.version >= Gem::Version.new('7.1')
      end

      def self.patch_postgresql_adapter!(adapter_class)
        require 'active_record/mti/connection_adapters/postgresql/schema_statements'
        require 'active_record/mti/connection_adapters/postgresql/adapter'

        adapter_class.prepend(::ActiveRecord::MTI::ConnectionAdapters::PostgreSQL::Adapter)
        adapter_class.prepend(::ActiveRecord::MTI::ConnectionAdapters::PostgreSQL::SchemaStatements)
      end
    end
  end
end
