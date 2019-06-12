module ActiveRecord
  module MTI
    module Table

      def self.find(klass, table_name, parent_class=klass.superclass)
        if concrete?(parent_class) && parent_mti_table = parent_class.mti_table
          ::ActiveRecord::MTI.child_tables.find(inhparent: parent_mti_table.oid, name: table_name) #|| parent_mti_table
        else
          ::ActiveRecord::MTI.parent_tables.find(name: table_name)
        end
      end

      def self.concrete?(klass)
        klass < ::ActiveRecord::Base && !klass.try(:abstract_class?)
      end

    end
  end
end
