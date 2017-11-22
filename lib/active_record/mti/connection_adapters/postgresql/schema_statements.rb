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

            if (schema = options.delete(:schema))
              # If we specify a schema then we only create it if it doesn't exist
              # and we only force create it if only the specific schema is in the search path
              table_name = %Q("#{schema}"."#{table_name}")
            end

            if (inherited_table = options.delete(:inherits))
              # options[:options] = options[:options].sub("INHERITS", "() INHERITS") if td.columns.empty?
              options[:options] = [%Q(INHERITS ("#{inherited_table}")), options[:options]].compact.join
            end

            results = super(table_name, options)

            if inherited_table
              inherited_table_primary_key = primary_key(inherited_table)
              execute %Q(ALTER TABLE "#{table_name}" ADD PRIMARY KEY ("#{inherited_table_primary_key}"))

              indexes(inherited_table).each do |index|
                attributes = index.to_h.slice(:unique, :using, :where, :orders)

                # Why rails insists on being inconsistant with itself is beyond me.
                attributes[:order] = attributes.delete(:orders)

                add_index table_name, index.columns, attributes
              end
            end

            results
          end

          # Parent of inherited table
          def parent_tables(table_name)
            result = exec_query(<<-SQL, "SCHEMA")
              SELECT pg_namespace.nspname, pg_class.relname
              FROM pg_catalog.pg_inherits
                INNER JOIN pg_catalog.pg_class ON (pg_inherits.inhparent = pg_class.oid)
                INNER JOIN pg_catalog.pg_namespace ON (pg_class.relnamespace = pg_namespace.oid)
              WHERE inhrelid = '#{table_name}'::regclass
            SQL
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
