module ActiveRecord
  # == Multi table inheritance
  #
  # PostgreSQL allows for table inheritance. To enable this in ActiveRecord, ensure that the
  # inheritance_column is named "tableoid" (can be changed by setting <tt>Base.inheritance_column</tt>).
  # This means that an inheritance looking like this:
  #
  #   class Company < ActiveRecord::Base;
  #     self.inheritance_column = 'tableoid'
  #   end
  #   class Firm < Company; end
  #   class Client < Company; end
  #   class PriorityClient < Client; end
  #
  # When you do <tt>Firm.create(name: "37signals")</tt>, this record will be saved in
  # the firms table which inherits from companies. You can then fetch this row again using
  # <tt>Company.where(name: '37signals').first</tt> and it will return a Firm object.
  #
  # Note, all the attributes for all the cases are kept in the same table. Read more:
  # http://www.martinfowler.com/eaaCatalog/singleTableInheritance.html
  #
  module MTI
    module Inheritance
      extend ActiveSupport::Concern

      module ClassMethods

        # We know we're using multi-table inheritance if the inheritance_column is not actually
        # present in the DB structure. Thereby implying the inheritance_column is inferred.
        # To further isolate usage of multi-table inheritance, the inheritance column must be set
        # to 'tableoid'
        def using_multi_table_inheritance?(klass = self)
          @using_multi_table_inheritance ||= if klass.columns_hash.include?(klass.inheritance_column)
            false
          elsif klass.inheritance_column == 'tableoid' && (klass.descendants.select{ |d| d.table_name != klass.table_name }.any?)
            true
          else
            false
          end
        end

        private

        # Called by +instantiate+ to decide which class to use for a new
        # record instance. For single-table inheritance, we check the record
        # for a +type+ column and return the corresponding class.
        def discriminate_class_for_record(record)
          if using_single_table_inheritance?(record)
            find_sti_class(record[inheritance_column])
          elsif using_multi_table_inheritance?(base_class)
            find_mti_class(record)
          else
            super
          end
        end

        # Search descendants for one who's table_name is equal to the returned tableoid.
        # This indicates the class of the record
        def find_mti_class(record)
          descendants.find(record['tableoid']&.singularize&.safe_constantize) { |d| d.table_name == record['tableoid'] }
        end

        # Type condition only applies if it's STI, otherwise it's
        # done for free by querying the inherited table in MTI
        def type_condition(table = arel_table)
          if using_multi_table_inheritance?
            nil
          else
            sti_column = table[inheritance_column]
            sti_names  = ([self] + descendants).map { |model| model.sti_name }

            sti_column.in(sti_names)
          end
        end

      end
    end
  end
end
