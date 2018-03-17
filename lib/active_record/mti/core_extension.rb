require 'active_support/concern'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string/inflections'

require 'active_record/mti/inheritance'
require 'active_record/mti/query_methods'
require 'active_record/mti/calculations'

module ActiveRecord
  module MTI
    module CoreExtension
      extend ActiveSupport::Concern

      included do
        initialize_load_mti_monitor
      end

      module ClassMethods #:nodoc:

        def base_model?
          (self == base_class ||
          superclass == ::ActiveRecord::Base ||
          superclass.abstract_class?) == true
        end

        def compute_mti_table_name(contained = nil)
          contained = contained_table_name if contained
          "#{full_table_name_prefix}#{contained}#{undecorated_table_name(name)}#{full_table_name_suffix}"
        end

        def contained_table_name
          if !base_model? && ActiveRecord::MTI.configuration.table_name_nesting
            contained_parent_table_name + ActiveRecord::MTI.configuration.nesting_seperator
          end
        end

        def contained_parent_table_name
          if ActiveRecord::MTI.configuration.singular_parent
            superclass.table_name.singularize
          else
            superclass.table_name
          end
        end

        def mti_table
          @mti_table ||= reset_mti_table
        end

        def sti_or_mti?
          !abstract_class? && self != base_class
        end

        # private

        def load_schema
          load_mti
          super
        end

          def mti_loaded?
            defined?(@mti_loaded) && @mti_loaded
          end

        protected

          def reset_mti_table
            @mti_table = \
              ::ActiveRecord::MTI.child_tables.find(:name, @table_name) ||
              ::ActiveRecord::MTI.child_tables.find(:name, compute_mti_table_name(true)) ||
              ::ActiveRecord::MTI.child_tables.find(:name, compute_mti_table_name) ||

              ::ActiveRecord::MTI.parent_tables.find(:name, @table_name) ||
              ::ActiveRecord::MTI.parent_tables.find(:name, compute_mti_table_name(true)) ||
              ::ActiveRecord::MTI.parent_tables.find(:name, compute_mti_table_name)
          end

          def initialize_load_mti_monitor
            @load_mti_monitor = Monitor.new
          end

          def load_mti
            return if mti_loaded?
            @load_mti_monitor.synchronize do
              return if defined?(@mti_table) && @mti_table

              unless self == ::ActiveRecord::Base || self.abstract_class? || !self.mti_table
                load_mti!
                ActiveRecord::MTI.registry[mti_table.oid] = self
              end

              @mti_loaded = true
            end
          end

        private

          def inherited(child_class)
            super
            child_class.initialize_load_mti_monitor
            child_class.load_mti
          end

          def load_mti!
            self.extend(::ActiveRecord::MTI::Inheritance)
            ar_r = self.const_get(:ActiveRecord_Relation)
            ar_r.prepend(::ActiveRecord::MTI::QueryMethods)
            ar_r.prepend(::ActiveRecord::MTI::Calculations)

            ActiveRecord::MTI.add_tableoid_attribute(self)
            reset_mti_table
          end

      end
    end
  end
end
