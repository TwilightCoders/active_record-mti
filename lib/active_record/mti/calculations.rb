module ActiveRecord
  module MTI
    module Calculations

      private

      def execute_simple_calculation(operation, column_name, distinct) #:nodoc:
        # Postgresql doesn't like ORDER BY when there are no GROUP BY
        relation = unscope(:order)

        column_alias = column_name

        bind_values = nil

        if operation == "count" && (relation.limit_value || relation.offset_value)
          # Shortcut when limit is zero.
          return 0 if relation.limit_value == 0

          query_builder = build_count_subquery(relation, column_name, distinct)
          bind_values = query_builder.bind_values + relation.bind_values
        else
          column = aggregate_column(column_name)

          select_value = operation_over_aggregate_column(column, operation, distinct)

          column_alias = select_value.alias
          column_alias ||= @klass.connection.column_name_for_operation(operation, select_value)
          relation.select_values = [select_value]

          # Only use the last projection (probably the COUNT(*)) all others don't matter
          # relation.arel.projections = [relation.arel.projections.last].compact if @klass.using_multi_table_inheritance?
          relation.arel.projections.shift if @klass.using_multi_table_inheritance?

          query_builder = relation.arel
          bind_values = query_builder.bind_values + relation.bind_values
        end

        result = @klass.connection.select_all(query_builder, nil, bind_values)
        row    = result.first
        value  = row && row.values.first
        column = result.column_types.fetch(column_alias) do
          type_for(column_name)
        end

        type_cast_calculated_value(value, column, operation)
      end

    end
  end
end
