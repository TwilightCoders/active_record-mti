module ActiveRecord
  module MTI
    module QueryMethods

      private

      # Retrieve the OID as well on a default select
      def build_select(arel)
        if @klass.using_multi_table_inheritance? && @klass.has_tableoid_column?
          arel.project(tableoid_cast(@klass))
        end

        if select_values.any?
          arel.project(*arel_columns(select_values.uniq))
        else
          arel.project(@klass.arel_table[Arel.star])
        end
      end

      def tableoid_cast(klass)
        # Arel::Nodes::NamedFunction.new('CAST', [klass.arel_table[:tableoid].as('regclass')])
        # Arel::Nodes::NamedFunction.new('CAST', [@klass.arel_table['tableoid::regclass'].as('regclass')])
        @klass.mti_tableoid_projection
      end

    end
  end
end
