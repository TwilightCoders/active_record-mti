module ActiveRecord
  module MTI
    module QueryMethods

      def build_arel
        select_by_tableoid = select_values.delete(:tableoid) == :tableoid
        group_by_tableoid = group_values.delete(:tableoid) == :tableoid

        arel = super

        if tableoid?(@klass) || group_by_tableoid || select_by_tableoid
          arel.project(tableoid_project(@klass))
          arel.group(tableoid_group(@klass)) if group_values.any? || group_by_tableoid
        end

        arel
      end

      private

      def tableoid?(klass)
        !Thread.current['skip_tableoid_cast'] &&
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
