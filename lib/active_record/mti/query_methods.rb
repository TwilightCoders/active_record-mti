module ActiveRecord
  module MTI
    module QueryMethods
      SINGLE_VALUE_METHODS = [:group_by_tableoid, :select_by_tableoid]

      SINGLE_VALUE_METHODS.each do |name|
        class_eval <<~RUBY, __FILE__, __LINE__ + 1
          def #{name}_value                    # def readonly_value
            @values[:#{name}]                  #   @values[:readonly]
          end                                  # end

          def #{name}_value=(value)            # def readonly_value=(value)
            assert_mutability!                 #   assert_mutability!
            @values[:#{name}] = value          #   @values[:readonly] = value
          end                                  # end
        RUBY
      end

      def build_arel
        self.select_by_tableoid_value = select_values.delete(:tableoid) || tableoid?(klass)
        self.group_by_tableoid_value = group_values.delete(:tableoid)

        super.tap do |arel|
          if group_by_tableoid_value || (select_by_tableoid_value && group_values.any?)
            arel.group(tableoid_group(@klass))
          end
        end
      end

      def build_select(arel)
        super.tap do |arel|
          arel.project(tableoid_project(@klass)) if (group_by_tableoid_value || select_by_tableoid_value)
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
