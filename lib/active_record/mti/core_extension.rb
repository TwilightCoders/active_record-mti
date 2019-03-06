require 'active_support/concern'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string/inflections'

require 'active_record/mti/relation'
# require 'active_record/mti/query_methods'
# require 'active_record/mti/calculations'

module ActiveRecord
  module MTI
    module CoreExtension

      def self.prepended(base)
        base.extend(ClassMethods)
      end

      module ClassMethods #:nodoc:

        def sti_or_mti?
          !abstract_class? && self != base_class
        end

        def mti?
          !mti_table.nil?
        end

        def mti_table
          reset_mti_table unless defined?(@mti_table)
          @mti_table
        end

        def mti_table_name
          mti_table&.name
        end

        # def table_name
        #   reset_table_name unless defined?(@table_name)
        #   @table_name
        # end

        def reset_mti_information
          # This might be "dangerous" if other gems have modified them as well.
          # It might be more prudent to call "inherited" which calls this as a
          # shared injection point, to play nice with other gems. (DeletedAt?)
          reinitialize_relation_delegate_cache

          # ActiveRecord::MTI.registry[mti_table&.oid] = self # maybe follow schema_cache pattern for this stuff
          # connection.mti_cache.clear_table_cache!(table_name)
          ActiveRecord::MTI[mti_table.oid] = nil
          @mti_table                       = nil
        end

        def reset_column_information
          reset_mti_information
          super
          ActiveRecord::MTI.add_tableoid_attribute(self)
          # connection.clear_cache!
          # undefine_attribute_methods
          # connection.schema_cache.clear_table_cache!(table_name)

          # @arel_engine        = nil
          # @column_names       = nil
          # @column_types       = nil
          # @content_columns    = nil
          # @default_attributes = nil
          # @inheritance_column = nil unless defined?(@explicit_inheritance_column) && @explicit_inheritance_column
          # @relation           = nil

          # initialize_find_by_cache
        end

        # def exclusively(tables=[self])
        #   all.tap do |ar|
        #     ar.exclusively(tables)
        #   end
        # end

        def mti_table=(value)
          if defined?(@mti_table)
            return if value == @mti_table
            reset_mti_information if connected?
          end

          @mti_table = value

          if mti_table
            # scope :naturally, -> {
            #   descendants.inject(only) { |ar|
            #     ar.join
            #   }
            # }

            # TODO: Use the list to retrieve ActiveRecord_Relation?
            ActiveRecord::MTI.registry[mti_table.oid] = self
            ar_r = self.const_get(:ActiveRecord_Relation)
            ar_r.prepend(::ActiveRecord::MTI::Relation)
          end
        end

        def table_name=(value)
          # value = value && value.to_s

          # if defined?(@table_name)
          #   return if value == @table_name
          #   reset_column_information if connected?
          # end

          # @table_name        = value
          # @quoted_table_name = nil
          # @arel_table        = nil
          # @sequence_name     = nil unless defined?(@explicit_sequence_name) && @explicit_sequence_name
          # @relation          = Relation.create(self, arel_table)
          super
          reset_mti_table
        end

        def reset_mti_table
          mti_table_name = defined?(@table_name) ? @table_name : compute_mti_table_name
          self.mti_table = ActiveRecord::MTI::Table.find(self, mti_table_name)
        end

        def compute_table_name
          mti_table_name || superclass.mti_table_name || super
        end

        def compute_mti_table_name
          # contained = (parent_name || '').split('::').join('/') { |part| part.downcase.singularize }
          if superclass < ::ActiveRecord::Base && !superclass.abstract_class?
            contained = superclass.table_name
            contained = contained.singularize if superclass.pluralize_table_names
            contained += '/'
          end
          "#{full_table_name_prefix}#{contained}#{undecorated_table_name(name)}#{full_table_name_suffix}"
        end

        # Returns +true+ if this does not need STI type condition. Returns
        # +false+ if STI type condition needs to be applied.
        def descends_from_active_record?
          a = mti?
          b = super
          c = superclass.respond_to?(:descends_from_active_record?) ? superclass.descends_from_active_record? : true
          # !(a || b || c) || !(!b || c) || (a && b && c)
          (!a && !b && c) || b

          # if self == Base
          #   false
          # elsif superclass.abstract_class?
          #   superclass.descends_from_active_record?
          # else
          #   superclass == Base || !columns_hash.include?(inheritance_column)
          # end
        end

        # Called by +instantiate+ to decide which class to use for a new
        # record instance. For single-table inheritance, we check the record
        # for a +type+ column and return the corresponding class.
        def discriminate_class_for_record(record)
          if (mti_class = ::ActiveRecord::MTI[record.delete('tableoid')])
            mti_class.discriminate_class_for_record(record)
          else
            super
          end
        end

        # Type condition only applies if it's STI, otherwise it's
        # done for free by querying the inherited table in MTI
        # def type_condition(table = arel_table)
        #   binding.pry
        #   mti_table ? nil : super
        #   # super unless mti_table
        # end

      protected

        def reinitialize_relation_delegate_cache
          @relation_delegate_cache.each do |klass, delegate|
            mangled_name = klass.name.gsub("::".freeze, "_".freeze)
            remove_const(mangled_name)
          end
          initialize_relation_delegate_cache
        end

      end
    end
  end
end
