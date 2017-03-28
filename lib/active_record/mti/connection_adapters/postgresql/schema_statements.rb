require 'active_record/connection_adapters/postgresql_adapter'

module ActiveRecord
  module MTI
    module ConnectionAdapters
      module PostgreSQL
        module SchemaStatements
          # Creates a new table with the name +table_name+. +table_name+ may either
          # be a String or a Symbol.
          #
          # Add :inherits options for Postgres table inheritance.  If a table is inherited then
          # the primary key column is also inherited.  Therefore the :primary_key options is set to false
          # so we don't duplicate that colume.
          #
          # However the primary key column from the parent is not inherited as primary key so
          # we manually add it.  Lastly we also create indexes on the child table to match those
          # on the parent table since indexes are also not inherited.
          def create_table(table_name, options = {})
            if options[:inherits]
              options[:id] = false
              options.delete(:primary_key)
            end

            if schema = options.delete(:schema)
              # If we specify a schema then we only create it if it doesn't exist
              # and we only force create it if only the specific schema is in the search path
              table_name = %Q("#{schema}"."#{table_name}")
            end

            if parent_table = options.delete(:inherits)
              options[:options] = [%Q(INHERITS ("#{parent_table}")), options[:options]].compact.join
            end

            td = create_table_definition table_name, options[:temporary], options[:options], options[:as]

            if options[:id] != false && !options[:as]
              pk = options.fetch(:primary_key) do
                Base.get_primary_key table_name.to_s.singularize
              end

              if pk.is_a?(Array)
                td.primary_keys pk
              else
                td.primary_key pk, options.fetch(:id, :primary_key), options
              end
            end

            yield td if block_given?

            if options[:force] && data_source_exists?(table_name)
              drop_table(table_name, options)
            end

            # Rails 5 wont create an empty column list which we might have if we're
            # working with inherited tables.  So we need to do that manually
            sql = schema_creation.accept(td)
            # sql = sql.sub("INHERITS", "() INHERITS") if td.columns.empty?

            result = execute sql

            if parent_table
              parent_table_primary_key = primary_key(parent_table)
              execute %Q(ALTER TABLE "#{table_name}" ADD PRIMARY KEY ("#{parent_table_primary_key}"))
              indexes(parent_table).each do |index|
                add_index table_name, index.columns, :unique => index.unique
              end
              # triggers_for_table(parent_table).each do |trigger|
              #   name = trigger.first
              #   definition = trigger.second.merge(on: table_name)
              #   create_trigger name, definition
              # end
            end

            td.indexes.each_pair { |c,o| add_index table_name, c, o }
          end

          # Parent of inherited table
          def parent_tables(table_name)
            sql = <<-SQL
              SELECT pg_namespace.nspname, pg_class.relname
              FROM pg_catalog.pg_inherits
                INNER JOIN pg_catalog.pg_class ON (pg_inherits.inhparent = pg_class.oid)
                INNER JOIN pg_catalog.pg_namespace ON (pg_class.relnamespace = pg_namespace.oid)
              WHERE inhrelid = '#{table_name}'::regclass
            SQL
            result = exec_query(sql, "SCHEMA")
            result.map{|a| a['relname']}
          end

          def parent_table(table_name)
            parents = parent_tables(table_name)
            parents.first
          end
        end
      end
    end
  end
end
