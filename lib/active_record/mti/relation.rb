require 'active_support/core_ext/object/blank'

module ActiveRecord
  module MTI
    module Relation

      def build_arel(*)
        super.tap do |ar|
          build_mti(ar)
        end
      end

      def build_mti(arel)
        if klass.tableoid?
          arel.project(tableoid_project) if !projecting_tableoid?(arel)
          arel.group(tableoid_group) if group_values.any?
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
