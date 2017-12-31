require 'active_support/concern'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string/inflections'

# require 'active_record/mti/parent/inheritance'
require 'active_record/mti/parent/query_methods'
require 'active_record/mti/parent/calculations'

module ActiveRecord
  module MTI
    module CoreExtension
      extend ActiveSupport::Concern

      def self.extend_parent(parent)
        # parent.extend(::ActiveRecord::MTI::Inheritance)
        parent.const_get(:ActiveRecord_Relation).prepend(::ActiveRecord::MTI::QueryMethods)
        parent.const_get(:ActiveRecord_Relation).prepend(::ActiveRecord::MTI::Calculations)
      end

      module ClassMethods #:nodoc:
        def inherited(subclass)
          super
          extend!
        end

        def child_tables
          @child_tables ||= (mti_table_as_parent ? ::ActiveRecord::MTI.child_tables.select {|table|
            table.inhparent == mti_table_as_parent.oid
          } : [])
        end

        def mti_table_as_parent
          @mti_table_as_parent ||= \
            (defined?(@table_name) && ::ActiveRecord::MTI.parent_tables.detect {|table| table.name == @table_name }) ||
            ::ActiveRecord::MTI.parent_tables.detect {|table| table.name == potential_mti_table_name } ||
            ::ActiveRecord::MTI.parent_tables.detect {|table| table.name == potential_table_name }
        end

        def mti_table
          @mti_table ||= sti_or_mti? &&
            (defined?(@table_name) && ::ActiveRecord::MTI.child_tables.detect {|table| table.name == @table_name }) ||
            ::ActiveRecord::MTI.child_tables.detect {|table| table.name == potential_mti_table_name } ||
            ::ActiveRecord::MTI.child_tables.detect {|table| table.name == potential_table_name }
        end

        def using_sti_or_mti?
          !abstract_class? && self != base_class
        end
        alias sti_or_mti? using_sti_or_mti?

        private

        def extend!(child = self)
          return if defined?(@extended) && @extended

          ::ActiveRecord::MTI::CoreExtension.extend_parent(self) if child_tables.present?

          @extended = true
        end

        def potential_mti_table_name
          if superclass < ::ActiveRecord::Base && !superclass.abstract_class?
            contained = superclass.table_name
            contained = contained.singularize if superclass.pluralize_table_names
            contained += '/'
          end

          "#{full_table_name_prefix}#{contained}#{undecorated_table_name(name)}#{full_table_name_suffix}"
        end

        def potential_table_name
          if parent < ::ActiveRecord::Base && !parent.abstract_class?
            contained = parent.table_name
            contained = contained.singularize if parent.pluralize_table_names
            contained += '_'
          end

          "#{full_table_name_prefix}#{contained}#{undecorated_table_name(name)}#{full_table_name_suffix}"
        end
      end
    end
  end
end
