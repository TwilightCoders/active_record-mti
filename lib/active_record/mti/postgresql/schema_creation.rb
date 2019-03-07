module ActiveRecord
  module MTI
    module PostgreSQL
      module SchemaCreation
        def add_table_options!(create_sql, options)
          if create_sql.chomp.last != ")"
            create_sql << "()"
          end
          super
        end
      end
    end
  end
end
