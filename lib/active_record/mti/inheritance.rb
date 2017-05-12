require 'active_support/concern'

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

      included do
        scope :discern_inheritance, -> {

        }
      end

      module ClassMethods

        def inherited(child)
          super
        end

        def uses_mti(table_name = nil, inheritance_column = nil)
          # self.table_name ||= table_name
          self.inheritance_column = inheritance_column

          @uses_mti = true
        end

        def using_multi_table_inheritance?(klass = self)
          klass.uses_mti?
        end

        def uses_mti?
          @uses_mti ||= check_inheritence_of(@table_name)
        end

        private

        def check_inheritence_of(table_name)
          return nil unless table_name

          result = connection.execute <<-SQL
            SELECT EXISTS ( SELECT 1
            FROM pg_catalog.pg_inherits
            WHERE inhrelid = 'public.#{table_name}'::regclass::oid
            OR inhparent = 'public.#{table_name}'::regclass::oid);
          SQL

          # Some versions of PSQL return {"?column?"=>"t"}
          # instead of {"first"=>"t"}, so we're saying screw it,
          # just give me the first value of whatever is returned
          result.try(:first).try(:values).try(:first) == 't'
        end

        # Called by +instantiate+ to decide which class to use for a new
        # record instance. For single-table inheritance, we check the record
        # for a +type+ column and return the corresponding class.
        def discriminate_class_for_record(record)
          if using_multi_table_inheritance?(base_class)
            find_mti_class(record)
          elsif using_single_table_inheritance?(record)
            find_sti_class(record[inheritance_column])
          else
            super
          end
        end

        # Search descendants for one who's table_name is equal to the returned tableoid.
        # This indicates the class of the record
        def find_mti_class(record)
          record['tableoid'].classify.constantize
        rescue NameError => e
          descendants.find(Proc.new{ self }) { |d| d.table_name == record['tableoid'] }
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
