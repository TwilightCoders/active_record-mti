require 'active_support/core_ext/object/blank'

module ActiveRecord
  module MTI
    module Relation

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
