module ActiveRecord
  module MTI
    module QueryMethods

      private

      def build_arel
        arel = Arel::SelectManager.new(table.engine, table)

        build_joins(arel, joins_values.flatten) unless joins_values.empty?

        collapse_wheres(arel, (where_values - [''])) #TODO: Add uniq with real value comparison / ignore uniqs that have binds

        arel.having(*having_values.uniq.reject(&:blank?)) unless having_values.empty?

        build_mti(arel)

        arel.take(connection.sanitize_limit(limit_value)) if limit_value
        arel.skip(offset_value.to_i) if offset_value
        arel.group(*arel_columns(group_values.uniq.reject(&:blank?))) unless group_values.empty?

        build_order(arel)

        build_select(arel)

        arel.distinct(distinct_value)
        arel.from(build_from) if from_value
        arel.lock(lock_value) if lock_value

        arel
      end

      # Retrieve the OID as well on a default select
      def build_mti(arel)

        select_by_tableoid = select_values.delete(:tableoid) == :tableoid
        group_by_tableoid = group_values.delete(:tableoid) == :tableoid

        if tableoid?(@klass) || group_by_tableoid || select_by_tableoid
          arel.project(tableoid_project(@klass))
          arel.group(tableoid_group(@klass)) if group_values.any? || group_by_tableoid
        end

      end

      def tableoid?(klass)
        !@skip_tableoid_cast &&
        @klass.using_multi_table_inheritance? &&
        @klass.has_tableoid_column?
      end

      def tableoid_project?(klass)
        tableoid?(klass) &&
        (group_values - [:tableoid]).any?
      end

      def tableoid_group?(klass)
        tableoid?(klass) &&
        group_values.any?
      end

      def tableoid_project(klass)
        # Arel::Nodes::NamedFunction.new('CAST', [klass.arel_table[:tableoid].as('regclass')])
        # Arel::Nodes::NamedFunction.new('CAST', [@klass.arel_table['tableoid::regclass'].as('regclass')])
        @klass.mti_type_column.as('tableoid')
      end

      def tableoid_group(klass)
        @klass.mti_type_column
      end

    end
  end
end
