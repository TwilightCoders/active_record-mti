module ActiveRecord
  module MTI
    module PostgreSQL
      module Adapter
        def column_definitions(table_name) # :nodoc:
          exec_query(<<-SQL, 'SCHEMA').rows
            SELECT a.attname, format_type(a.atttypid, a.atttypmod),
                pg_get_expr(d.adbin, d.adrelid), a.attnotnull, a.atttypid, a.atttypmod
            FROM pg_attribute a LEFT JOIN pg_attrdef d
              ON a.attrelid = d.adrelid AND a.attnum = d.adnum
            WHERE a.attrelid = '#{quote_table_name(table_name)}'::regclass
              AND a.attnum > 0 AND NOT a.attisdropped
              AND a.attname != 'tableoid'
            ORDER BY a.attnum
          SQL
        end
      end
    end
  end
end
