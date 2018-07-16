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

      # def reset_table_name #:nodoc:
      #   @table_name = nil
      #   self.table_name = compute_table_name || super
      # end

      def compute_table_name
        mti_table&.name || superclass.mti_table&.name || super
      end

      # def compute_table_name
      #   if self != base_class
      #     # Nested classes are prefixed with singular parent table name.
      #     if superclass < Base && !superclass.abstract_class?
      #       contained = superclass.table_name
      #       contained = contained.singularize if superclass.pluralize_table_names
      #       contained += '/'
      #     end

      #     potential_table_name = "#{full_table_name_prefix}#{contained}#{decorated_table_name(name)}#{full_table_name_suffix}"

      #     if check_inheritance_of(potential_table_name)
      #       potential_table_name
      #     else
      #       superclass.table_name
      #     end
      #   else
      #     super
      #   end
      # end

      # Type condition only applies if it's STI, otherwise it's
      # done for free by querying the inherited table in MTI
      def type_condition(table = arel_table)
        super unless mti_table
      end

    end
  end
end
