require 'active_support/core_ext/object/blank'

module ActiveRecord
  module MTI
    module QueryMethods
      def build_arel
        select_by_tableoid = select_values.delete(:tableoid) == :tableoid
        group_by_tableoid = group_values.delete(:tableoid) == :tableoid

        arel = super

        if tableoid? || group_by_tableoid || select_by_tableoid
          arel.project(tableoid_project(klass))
          arel.group(tableoid_group(klass)) if group_values.any? || group_by_tableoid
        end

        arel
      end

      private

      def tableoid?
        !Thread.current['skip_tableoid_cast'] && klass.child_tables.present?
      end

      def tableoid_project(klass)
        klass.arel_table[:tableoid].as('tableoid')
      end

      def tableoid_group(klass)
        klass.arel_table[:tableoid]
      end
    end
  end
end
