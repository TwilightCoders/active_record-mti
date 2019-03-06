require 'active_support/core_ext/object/blank'

module ActiveRecord
  module MTI
    module Relation

      # Consider using a join to avoid complicated selects?
      # Maybe each "mti" belongs_to :mti_table foreign_key: :tableoid?
      # SELECT p.relname, c.name, c.altitude
      # FROM cities c, pg_class p
      # WHERE c.altitude > 500 AND c.tableoid = p.oid;


      # TODO: Introduce natural joins
      # https://dba.stackexchange.com/questions/94050/query-parent-table-and-get-child-tables-columns
      # EXPLAIN ANALYSE SELECT * FROM ONLY listeners NATURAL FULL JOIN "listeners/bridge/all";

      # EXPLAIN ANALYSE SELECT * FROM "listeners/bridge/all";

      # EXPLAIN ANALYSE SELECT * FROM listeners;

      # EXPLAIN ANALYSE SELECT * FROM ONLY listeners
      #   NATURAL FULL JOIN "listeners/bridge/all"
      #   NATURAL FULL JOIN "listeners/integration/all"
      #   NATURAL FULL JOIN "listeners/nest_thermostat/all"
      #   NATURAL FULL JOIN "listeners/sensor/all"
      #   NATURAL FULL JOIN "listeners/system/all"
      #   NATURAL FULL JOIN "listeners/system_users/all"
      #   NATURAL FULL JOIN "listeners/user/all";

      def build_arel(*)
        select_by_tableoid = select_values.delete(:tableoid) == :tableoid
        group_by_tableoid = group_values.delete(:tableoid) == :tableoid

        super.tap do |arel|
          if tableoid? || group_by_tableoid || select_by_tableoid
            arel.project(tableoid_project(klass))
            arel.group(tableoid_group(klass)) if group_values.any? || group_by_tableoid
          end
        end
      end

      # def exclusively(tables=[klass])
      #   @table = table.dup.tap do |t|
      #     t.only!
      #   end
      #   binding.pry
      #   self
      # end

      private

      def perform_calculation(*)
        Thread.reverb(:skip_tableoid_cast, true) do
          super
        end
      end

      def tableoid?
        !Thread.current[:skip_tableoid_cast] && klass.mti_table.present?
      end

      def tableoid_project(klass)
        klass.arel_table[:tableoid].as('tableoid')
      end

      def tableoid_group(klass)
        klass.arel_table[:tableoid]
      end
    end
  end
end
