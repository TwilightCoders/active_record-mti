module ActiveRecord
  module MTI
    module QueryMethods

      def build_arel
        @select_by_tableoid = [select_values.delete(:tableoid), tableoid?(klass)].compact.first
        @group_by_tableoid = group_values.delete(:tableoid)

        super.tap do |arel|
          if @group_by_tableoid || (@select_by_tableoid && group_values.any?)
            arel.group(tableoid_group(@klass))
          end
        end
      end

      def build_select(*args)
        super.tap do |arel|
          arel.project(tableoid_project(@klass)) if (@group_by_tableoid || @select_by_tableoid)
        end
      end

      private

      def tableoid?(klass)
        !Thread.current['skip_tableoid_cast'] &&
        klass.using_multi_table_inheritance? &&
        klass.mti_type_column
      end

      def tableoid_project(klass)
        klass.mti_type_column.as('tableoid')
      end

      def tableoid_group(klass)
        klass.mti_type_column
      end

    end
  end
end
