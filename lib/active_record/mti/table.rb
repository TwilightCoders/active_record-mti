module ActiveRecord
  module MTI
    module Table

      def self.find(klass, table_name, parent_class = klass.superclass)
        if concrete?(parent_class) && (parent_mti_table = parent_class.mti_table)
          ::ActiveRecord::MTI.child_tables.detect { |t|
            t.inhparent.to_s == parent_mti_table.oid.to_s && t.name == table_name
          }
        else
          ::ActiveRecord::MTI.parent_tables.detect { |t| t.name == table_name }
        end
      end

      def self.concrete?(klass)
        klass < ::ActiveRecord::Base && !klass.try(:abstract_class?)
      end

    end
  end
end
