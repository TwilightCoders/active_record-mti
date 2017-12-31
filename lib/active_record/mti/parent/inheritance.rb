module ActiveRecord
  # == Multi-Table Inheritance
  module MTI
    module Inheritance
      # Called by +instantiate+ to decide which class to use for a new
      # record instance. For single-table inheritance, we check the record
      # for a +type+ column and return the corresponding class.
      def discriminate_class_for_record(record)
        klass = ::ActiveRecord::MTI.registry[record['tableoid']]
        klass ||= begin
                    table = child_tables.detect {|table| table.inhrelid == record['tableoid'] }
                    table && table.name.classify.safe_constantize
                  end

        klass || self
      end

      # Type condition only applies if it's STI, otherwise it's
      # done for free by querying the inherited table in MTI
      def type_condition(table = arel_table)
        super unless mti_table
      end
    end
  end
end
