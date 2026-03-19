module ActiveRecord
  module MTI
    module ConnectionAdapters
      module PostgreSQL
        module Adapter
          # Filter out the tableoid system column from column definitions.
          # Rather than replacing the entire SQL query (which changes across
          # Rails versions), we call super and filter the result.
          def column_definitions(table_name)
            super.reject { |row| row[0] == 'tableoid' }
          end
        end
      end
    end
  end
end
