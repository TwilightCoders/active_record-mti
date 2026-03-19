# Modified SchemaDumper that knows how to dump
# inherited tables. Key is that we have to dump parent
# tables before we dump child tables (of course).
# In addition we have to make sure we don't dump columns
# that are inherited.
module ActiveRecord
  module MTI
    module SchemaDumper #:nodoc:
      def dumped_tables
        @dumped_tables ||= []
      end

      # Output table and columns - but don't output columns that are inherited from
      # a parent table.
      def table(table, stream)
        return if already_dumped?(table)

        new_stream = StringIO.new
        super(table, new_stream)
        string = new_stream.string

        if (parent_table = @connection.parent_table(table))
          table(parent_table, stream)
          string = inject_inherits_for_create_table(string, table, parent_table)
          string = remove_parent_table_columns(string, @connection.columns(parent_table))

          parent_idx = @connection.indexes(parent_table).map { |i| [i.columns, i] }.to_h
          child_idx  = @connection.indexes(table).map { |i| [i.columns, i] }.to_h
          shared_keys = parent_idx.keys & child_idx.keys
          shared_indexes = shared_keys.map { |k| child_idx[k] }

          string = remove_parent_table_indexes(string, shared_indexes)
        end

        dumped_tables << table

        stream.write string
        stream
      end

      def inject_inherits_for_create_table(string, table, parent_table)
        tbl_start = "create_table #{remove_prefix_and_suffix(table).inspect}"
        tbl_end = ' do |t|'
        tbl_inherit = ", inherits: '#{parent_table}'"
        string.gsub!(/#{Regexp.escape(tbl_start)}.*#{Regexp.escape(tbl_end)}/, tbl_start + tbl_inherit + tbl_end)
        string
      end

      def remove_parent_table_columns(string, columns)
        columns.each do |col|
          string.gsub!(/\s+t\.\w+\s+("|')#{col.name}("|').*/, '')
        end
        string
      end

      def remove_parent_table_indexes(string, indexes)
        indexes.each do |index|
          string.gsub!(/\s*add_index .*name: #{Regexp.escape(index.name.inspect)}.*/, '') # Rails 4.x
          string.gsub!(/\s+t\.index.*("|')#{index.name}("|').*/, '') # Rails 5.x
        end
        string
      end

      def remove_prefix_and_suffix(table)
        table.gsub(/^(#{ActiveRecord::Base.table_name_prefix})(.+)(#{ActiveRecord::Base.table_name_suffix})$/, '\\2')
      end

      def already_dumped?(table)
        dumped_tables.include? table
      end
    end
  end
end
