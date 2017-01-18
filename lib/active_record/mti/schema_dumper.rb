# Modified SchemaDumper that knows how to dump
# inherited tables. Key is that we have to dump parent
# tables before we dump child tables (of course).
# In addition we have to make sure we don't dump columns
# that are inherited.
module ActiveRecord
  # = Active Record Schema Dumper
  #
  # This class is used to dump the database schema for some connection to some
  # output format (i.e., ActiveRecord::Schema).
  module MTI
    module SchemaDumper #:nodoc:
      extend ActiveSupport::Concern


      included do

        private

        def dumped_tables
          @dumped_tables ||= []
        end

        # Output table and columns - but don't output columns that are inherited from
        # a parent table.
        #
        # TODO: Qualify with the schema name IF the table is in a schema other than the first
        # schema in the search path (not including the $user schema)
        def table(table, stream)
          return if already_dumped?(table)
          if parent_table = @connection.parent_table(table)
            table(parent_table, stream)
            parent_column_names = @connection.columns(parent_table).map(&:name)
          end

          columns = @connection.columns(table)
          begin
            tbl = StringIO.new

            # first dump primary key column
            pk = @connection.primary_key(table)

            tbl.print "  create_table #{remove_prefix_and_suffix(table).inspect}"
            if parent_table
              tbl.print %Q(, inherits: '#{parent_table}')
            else
              pkcol = columns.detect { |c| c.name == pk }
              if pkcol
                if pk != 'id'
                  tbl.print %Q(, primary_key: '#{pk}')
                elsif pkcol.sql_type == 'bigint'
                  tbl.print ", id: :bigserial"
                elsif pkcol.sql_type == 'uuid'
                  tbl.print ", id: :uuid"
                  tbl.print %Q(, default: #{pkcol.default_function.inspect})
                end
              else
                tbl.print ", id: false"
              end
              tbl.print ", force: :cascade"
            end
            tbl.puts " do |t|"

            # then dump all non-primary key columns
            column_specs = columns.map do |column|
              raise StandardError, "Unknown type '#{column.sql_type}' for column '#{column.name}'" unless @connection.valid_type?(column.type)
              next if column.name == pk

              # Except columns in parent table
              next if parent_column_names && parent_column_names.include?(column.name)

              @connection.column_spec(column, @types)
            end.compact

            # find all migration keys used in this table
            keys = @connection.migration_keys

            # figure out the lengths for each column based on above keys
            lengths = keys.map { |key|
              column_specs.map { |spec|
                spec[key] ? spec[key].length + 2 : 0
              }.max
            }

            # the string we're going to sprintf our values against, with standardized column widths
            format_string = lengths.map{ |len| "%-#{len}s" }

            # find the max length for the 'type' column, which is special
            type_length = column_specs.map{ |column| column[:type].length }.max

            # add column type definition to our format string
            format_string.unshift "    t.%-#{type_length}s "

            format_string *= ''

            column_specs.each do |colspec|
              values = keys.zip(lengths).map{ |key, len| colspec.key?(key) ? colspec[key] + ", " : " " * len }
              values.unshift colspec[:type]
              tbl.print((format_string % values).gsub(/,\s*$/, ''))
              tbl.puts
            end

            tbl.puts "  end"
            tbl.puts

            indexes(table, tbl)

            tbl.rewind
            stream.print tbl.read
          rescue => e
            stream.puts "# Could not dump table #{table.inspect} because of following #{e.class}"
            stream.puts "#   #{e.message}"
            stream.puts
          end

          dumped_tables << table
          stream
        end

        # Output indexes but don't output indexes that are inherited from parent tables
        # since those will be created by create_table.
        def indexes(table, stream)
          if (indexes = @connection.indexes(table)).any?
            if parent_table = @connection.parent_table(table)
              parent_indexes = @connection.indexes(parent_table)
            end

            indexes.delete_if {|i| is_parent_index?(i, parent_indexes) } if parent_indexes
            return if indexes.empty?

            add_index_statements = indexes.map do |index|
              statement_parts = [
                ('add_index ' + remove_prefix_and_suffix(index.table).inspect),
                index.columns.inspect,
                ('name: ' + index.name.inspect),
              ]
              statement_parts << 'unique: true' if index.unique

              index_lengths = (index.lengths || []).compact
              statement_parts << ('length: ' + Hash[index.columns.zip(index.lengths)].inspect) unless index_lengths.empty?

              index_orders = (index.orders || {})
              statement_parts << ('order: ' + index.orders.inspect) unless index_orders.empty?

              statement_parts << ('where: ' + index.where.inspect) if index.where

              statement_parts << ('using: ' + index.using.inspect) if index.using

              statement_parts << ('type: ' + index.type.inspect) if index.type

              '  ' + statement_parts.join(', ')
            end

            stream.puts add_index_statements.sort.join("\n")
            stream.puts
          end
        end


        def remove_prefix_and_suffix(table)
          table.gsub(/^(#{ActiveRecord::Base.table_name_prefix})(.+)(#{ActiveRecord::Base.table_name_suffix})$/,  "\\2")
        end

        def already_dumped?(table)
          dumped_tables.include? table
        end

        def is_parent_index?(index, parent_indexes)
          parent_indexes.each do |pindex|
            return true if pindex.columns == index.columns
          end
          return false
        end
      end
    end
  end
end
