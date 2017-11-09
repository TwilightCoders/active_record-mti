module ActiveRecord
  module MTI
    module Calculations

      private

      def perform_calculation(operation, column_name, options = {})
        # TODO: Remove options argument as soon we remove support to
        # activerecord-deprecated_finders.
        operation = operation.to_s.downcase

        # If #count is used with #distinct / #uniq it is considered distinct. (eg. relation.distinct.count)
        distinct = self.distinct_value

        if operation == "count"
          column_name ||= select_for_count

          unless arel.ast.grep(Arel::Nodes::OuterJoin).empty?
            distinct = true
          end

          column_name = primary_key if column_name == :all && distinct
          distinct = nil if column_name =~ /\s*DISTINCT[\s(]+/i
        end

        swap_and_restore_tableoid_cast(true) do
          if group_values.any?
            execute_grouped_calculation(operation, column_name, distinct)
          else
            execute_simple_calculation(operation, column_name, distinct)
          end
        end
      end

      def swap_and_restore_tableoid_cast(value, &block)
        orignal_value = Thread.current['skip_tableoid_cast']
        Thread.current['skip_tableoid_cast'] = value
        return_value = yield
        Thread.current['skip_tableoid_cast'] = orignal_value
        return return_value
      end

    end
  end
end
