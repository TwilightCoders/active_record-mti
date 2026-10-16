require 'active_support/core_ext/object/blank'

module ActiveRecord
  module MTI
    module Relation

      def build_arel(*)
        super.tap do |ar|
          build_mti(ar)
        end
      end

      # `pluck` asks for an explicit list of columns and returns raw values, never model
      # instances — so it needs no discrimination, and a tableoid it did not ask for silently
      # corrupts its result shape. See #pluck below.
      def build_mti(arel)
        return if ThreadContext.active?(:skip_tableoid_projection)

        if klass.tableoid?
          arel.project(tableoid_project) unless projecting_tableoid?(arel)
          arel.group(tableoid_group) if group_values.any?
        end
      end

      # build_mti projects tableoid onto every relation, and pluck returns the whole projection,
      # so without this every pluck on an MTI model returns an extra value per row
      # (`User.pluck(:email) # => [["a@example.com", 16385], ...]`). It fails silently, and
      # neither `from("ONLY …")` nor `pluck(Arel.sql(...))` avoids it, so it is suppressed here,
      # at the producer, for the duration of the pluck only, as #perform_calculation already
      # suppresses the tableoid cast for calculations.
      def pluck(*column_names)
        ThreadContext.with(:skip_tableoid_projection, true) do
          super
        end
      end

      # Same trap, same fix. Rails 7.1+ implements #ids with its own select_all over the
      # relation's arel rather than delegating to #pluck, so the tableoid projection leaked
      # into it too: `User.ids # => [[1, 32779], [2, 32791]]`. On older Rails #ids calls
      # #pluck and the nested suppression is harmless.
      def ids
        ThreadContext.with(:skip_tableoid_projection, true) do
          super
        end
      end

      def projecting_tableoid?(arel)
        arel.projections.any? do |projection|
          tableoid_projection?(projection)
        end
      end

      def tableoid_projection?(projection)
        case projection
        when Arel::Attributes::Attribute
          projection.relation.name == klass.table_name && projection.name.to_s == 'tableoid'
        when Arel::Nodes::As
          tableoid_projection?(projection.left)
        when Arel::Nodes::SqlLiteral
          projection == 'tableoid'
        else
          false
        end
      end

      private

      def perform_calculation(*)
        ThreadContext.with(:skip_tableoid_cast, true) do
          super
        end
      end

      def tableoid_project
        arel_table[:tableoid]
      end

      def tableoid_group
        arel_table[:tableoid]
      end
    end
  end
end
