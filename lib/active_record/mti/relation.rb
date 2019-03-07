require 'active_support/core_ext/object/blank'

module ActiveRecord
  module MTI
    module Relation

      def build_arel(*)
        super.tap do |arel|
          build_mti(arel)
        end
      end

      private

      def build_mti(arel)
        if tableoid? || group_by_tableoid? || select_by_tableoid?
          arel.project(tableoid_project(klass))
          arel.group(tableoid_group(klass)) if group_values.any? || group_by_tableoid?
        end
      end

      def perform_calculation(*)
        Thread.reverb(:skip_tableoid_cast, true) do
          super
        end
      end

      def select_by_tableoid?
        @select_by_tableoid = if defined?(@select_by_tableoid)
          @select_by_tableoid
        else
          select_values.delete(:tableoid) == :tableoid
        end
      end

      def group_by_tableoid?
        @group_by_tableoid = if defined?(@group_by_tableoid)
          @group_by_tableoid
        else
          group_values.delete(:tableoid) == :tableoid
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
