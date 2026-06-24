module ActiveRecord
  module MTI
    module ConnectionAdapters
      module PostgreSQL
        module SchemaStatements

          def create_table(table_name, **options)
            if (inherited_table = options.delete(:inherits))
              options[:id] = false
              options.delete(:primary_key)
              options[:options] = [%(INHERITS ("#{inherited_table}")), options[:options]].compact.join
            end

            options.delete(:schema)

            super(table_name, **options) do |td|
              yield(td) if block_given?
              fix_inherits_statement(td) if inherited_table
            end.tap do
              inherit_indexes(table_name, inherited_table) if inherited_table
            end
          end

          def parent_table(table_name)
            parent_tables(table_name).first
          end

          def parent_tables(table_name)
            escaped = table_name.to_s.gsub("'", "''")
            exec_query(<<~SQL, 'SCHEMA').map { |row| row['relname'] }
              SELECT pg_namespace.nspname, pg_class.relname
              FROM pg_catalog.pg_inherits
                INNER JOIN pg_catalog.pg_class ON (pg_inherits.inhparent = pg_class.oid)
                INNER JOIN pg_catalog.pg_namespace ON (pg_class.relnamespace = pg_namespace.oid)
              WHERE inhrelid = '#{escaped}'::regclass
            SQL
          end

        private

          def fix_inherits_statement(td)
            return unless td.respond_to?(:columns) && td.columns.empty?
            # Only inject the empty column list when the body is *truly* empty. A table with
            # a CHECK constraint already emits a "(CONSTRAINT ...)" group, so prepending "()"
            # would produce the invalid double group "(CONSTRAINT ...) () INHERITS (...)".
            return unless (td.try(:check_constraints) || []).empty?
            td.options.gsub!('INHERITS', '() INHERITS') if td.options.respond_to?(:gsub!)
          end

          def inherit_indexes(table_name, inherited_table)
            pk = primary_key(inherited_table)
            execute %(ALTER TABLE "#{table_name}" ADD PRIMARY KEY ("#{pk}")) if pk

            indexes(inherited_table).each do |index|
              attrs = extract_index_attributes(index)
              attrs[:order] = attrs.delete(:orders)

              if (idx_name = build_index_name(attrs.delete(:name), inherited_table, table_name))
                attrs[:name] = idx_name
              end

              add_index table_name, index.columns, **attrs
            end
          end

          def extract_index_attributes(index)
            %i[unique using where orders name].each_with_object({}) do |attr, hash|
              hash[attr] = index.public_send(attr)
            end
          end

          def build_index_name(index_name, inherited_table, table_name)
            return unless index_name
            schema, name = index_name.match(/(?:(?<schema>.*)\.)?(?<name>.*)/).captures
            name = if name.include?(inherited_table.to_s)
                     name.gsub(inherited_table.to_s, table_name.to_s)
                   else
                     "#{table_name}/#{name}"
                   end
            [schema, name].compact.join('.')
          end
        end
      end
    end
  end
end
