module ActiveRecord
  module MTI
    module ConnectionAdapters
      module PostgreSQL
        module Adapter
          def column_definitions(table_name) # :nodoc:
            # Override to filter out the 'tableoid' system column.
            # Must match Rails 8.1's column list: attname, format_type, default_expr,
            # attnotnull, atttypid, atttypmod, collname, comment, identity, attgenerated
            query(<<~SQL, "SCHEMA")
              SELECT a.attname, format_type(a.atttypid, a.atttypmod),
                     pg_get_expr(d.adbin, d.adrelid), a.attnotnull, a.atttypid, a.atttypmod,
                     c.collname, col_description(a.attrelid, a.attnum) AS comment,
                     #{supports_identity_columns? ? 'attidentity' : quote('')} AS identity,
                     #{supports_virtual_columns? ? 'attgenerated' : quote('')} AS attgenerated
                FROM pg_attribute a
                LEFT JOIN pg_attrdef d ON a.attrelid = d.adrelid AND a.attnum = d.adnum
                LEFT JOIN pg_type t ON a.atttypid = t.oid
                LEFT JOIN pg_collation c ON a.attcollation = c.oid AND a.attcollation <> t.typcollation
               WHERE a.attrelid = #{quote(quote_table_name(table_name))}::regclass
                 AND a.attnum > 0 AND NOT a.attisdropped
                 AND a.attname != 'tableoid'
               ORDER BY a.attnum
            SQL
          end
        end
      end
    end
  end
end
