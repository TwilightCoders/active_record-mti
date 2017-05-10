module ActiveRecord
  module MTI
    module Calculations

      private

      def execute_grouped_calculation(operation, column_name, distinct) #:nodoc:
        group_attrs = group_values

        if group_attrs.first.respond_to?(:to_sym)
          association  = @klass._reflect_on_association(group_attrs.first)
          associated   = group_attrs.size == 1 && association && association.belongs_to? # only count belongs_to associations
          group_fields = Array(associated ? association.foreign_key : group_attrs)
        else
          group_fields = group_attrs
        end
        group_fields = arel_columns(group_fields)

        group_aliases = group_fields.map { |field|
          column_alias_for(field)
        }
        group_columns = group_aliases.zip(group_fields).map { |aliaz,field|
          [aliaz, field]
        }

        group = group_fields

        if operation == 'count' && column_name == :all
          aggregate_alias = 'count_all'
        else
          aggregate_alias = column_alias_for([operation, column_name].join(' '))
        end

        select_values = [
          operation_over_aggregate_column(
            aggregate_column(column_name),
            operation,
            distinct).as(aggregate_alias)
        ]
        select_values += select_values unless having_values.empty?

        select_values.concat group_fields.zip(group_aliases).map { |field,aliaz|
          if field.respond_to?(:as)
            field.as(aliaz)
          else
            "#{field} AS #{aliaz}"
          end
        }

        relation = except(:group)
        relation.group_values  = group
        relation.select_values = select_values

        # Remove our cast otherwise PSQL will insist that it be included in the GROUP
        relation.arel.projections.select!{ |p| p.to_s != "CAST(\"#{klass.table_name}\".\"tableoid\"::regclass AS text)" } if @klass.using_multi_table_inheritance?

        calculated_data = @klass.connection.select_all(relation, nil, relation.arel.bind_values + bind_values)

        if association
          key_ids     = calculated_data.collect { |row| row[group_aliases.first] }
          key_records = association.klass.base_class.find(key_ids)
          key_records = Hash[key_records.map { |r| [r.id, r] }]
        end

        Hash[calculated_data.map do |row|
          key = group_columns.map { |aliaz, col_name|
            column = calculated_data.column_types.fetch(aliaz) do
              type_for(col_name)
            end
            type_cast_calculated_value(row[aliaz], column)
          }
          key = key.first if key.size == 1
          key = key_records[key] if associated

          column_type = calculated_data.column_types.fetch(aggregate_alias) { type_for(column_name) }
          [key, type_cast_calculated_value(row[aggregate_alias], column_type, operation)]
        end]
      end

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

          # Remove our cast otherwise PSQL will insist that it be included in the GROUP
          # Somewhere between line 82 and 101 relation.arel.projections gets reset :/
          relation.arel.projections.select!{ |p| p.to_s != "CAST(\"#{klass.table_name}\".\"tableoid\"::regclass AS text)" } if @klass.using_multi_table_inheritance?

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
