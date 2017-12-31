module ActiveRecord
  module MTI
    module ModelSchema
      def compute_table_name
        if sti_or_mti? && mti_table.nil?
          superclass.table_name
        else
          (mti_table && mti_table.name) || super
        end
      end
    end
  end
end
