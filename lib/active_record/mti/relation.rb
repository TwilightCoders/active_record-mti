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
        return if Thread.currently?(:skip_tableoid_projection)

        if klass.tableoid?
          arel.project(tableoid_project) if !projecting_tableoid?(arel)
          arel.group(tableoid_group) if group_values.any?
        end
      end

      # THE TUPLE TRAP. Without this, every pluck on an MTI model returns N+1 values per row:
      #
      #   Evidence.pluck(:evidence_type)        => [["summarizes", 210031], ...]
      #   Conversation.pluck(:provider)         => [["claude_code", 113248], ...]
      #   Evidence.pluck(:evidence_type, :note) => [["summarizes", nil, 210031], ...]
      #
      # because build_mti projects tableoid onto every relation and pluck faithfully returns
      # the whole projection: `SELECT "evidence"."evidence_type", "evidence"."tableoid" FROM ...`
      #
      # It fails SILENTLY and plausibly, which is what makes it expensive: `id == x` is simply
      # false, `include?` simply misses, `uniq` simply doesn't dedupe. One consuming app measured
      # "0 agreements, 37 disagreements" between two id sets that in truth agreed 33 times with
      # zero disagreements — nothing raised, and the numbers looked like a real architectural
      # problem. It bit four separate work streams in that app in a single day, twice in the same
      # hour to one person who had already read the warning comment about it.
      #
      # Affects every column type, is not avoided by `from("ONLY …")`, and is not avoided by
      # `pluck(Arel.sql(...))` — the projection is appended after the caller's select list either
      # way. Suppressing it here, at the producer, is the only place a caller cannot get wrong.
      #
      # The discrimination mechanism is untouched: this suppresses the projection ONLY for the
      # duration of a pluck, exactly as #perform_calculation already suppresses the tableoid cast
      # for calculations.
      def pluck(*column_names)
        Thread.currently(:skip_tableoid_projection, true) do
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
        Thread.currently(:skip_tableoid_cast, true) do
          super
        end
      end

      def tableoid_project
        arel_table[:tableoid]#.as('tableoid')
      end

      def tableoid_group
        arel_table[:tableoid]
      end
    end
  end
end
