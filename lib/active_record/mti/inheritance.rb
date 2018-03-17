require 'active_support/core_ext/string/inflections'

module ActiveRecord
  # == Multi-Table Inheritance
  module MTI
    module Inheritance
      # Called by +instantiate+ to decide which class to use for a new
      # record instance. For single-table inheritance, we check the record
      # for a +type+ column and return the corresponding class.
      def discriminate_class_for_record(record)
        ::ActiveRecord::MTI.registry[record['tableoid']] || super
      end

      def reset_table_name #:nodoc:
          @table_name = nil
          self.table_name = reset_mti_table&.name || superclass.table_name || super
      end

      def compute_table_name
        mti_table&.name || super
      end

      # Type condition only applies if it's STI, otherwise it's
      # done for free by querying the inherited table in MTI
      def type_condition(table = arel_table)
        super unless mti_table
      end

    end
  end
end
