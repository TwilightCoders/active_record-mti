require 'active_support/concern'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string/inflections'

require 'active_record/mti/relation'

module ActiveRecord
  module MTI
    module CoreExtension

      def self.prepended(base)
        base.singleton_class.prepend(ClassMethods)
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

        def reset_mti_information
          reinitialize_relation_delegate_cache

          ActiveRecord::MTI[mti_table.oid] = nil if mti?
          @mti_table                       = nil
          @columns_hash&.delete("tableoid")
        end

        def reset_column_information
          super.tap do
            reset_mti_information
          end
        end

        def tableoid?
          !Thread.currently?(:skip_tableoid_cast) && mti?
        end

        def tableoid
          mti_table&.oid
        end

        def mti_table=(value)
          @mti_table = value

          if mti_table
            self.attribute :tableoid, ActiveRecord::MTI.oid_class.new

            ActiveRecord::MTI.registry[mti_table.oid] = self

            @relation_delegate_cache.each do |klass, delegate|
              delegate.prepend(::ActiveRecord::MTI::Relation)
            end
          end
        end

        def table_name=(value)
          super.tap do
            reset_mti_table if connected?
          end
        end

        def load_schema!
          super
        end

        def reset_mti_table
          mti_table_name = defined?(@table_name) ? @table_name : compute_mti_table_name
          self.mti_table = ActiveRecord::MTI::Table.find(self, mti_table_name)
        end

        def compute_table_name
          mti_table_name || superclass.mti_table_name || super
        end

        def compute_mti_table_name
          if superclass < ::ActiveRecord::Base && !superclass.abstract_class?
            contained = superclass.table_name
            contained = contained.singularize if superclass.pluralize_table_names
            contained += '/'
          end
          "#{full_table_name_prefix}#{contained}#{undecorated_table_name(name)}#{full_table_name_suffix}"
        end

        def discriminate_class_for_record(record)
          if (mti_class = ::ActiveRecord::MTI[record.delete('tableoid')])
            mti_class.discriminate_class_for_record(record)
          else
            super
          end
        end

      protected

        def add_tableoid_column
          # Build a proper Column object compatible with Rails 8.x
          # tableoid is a system column (OID type, oid=26) that PG manages
          cast_type = ActiveRecord::MTI.oid_class.new
          sql_type_metadata = ActiveRecord::ConnectionAdapters::SqlTypeMetadata.new(
            sql_type: "oid",
            type: :integer
          )
          column = ActiveRecord::ConnectionAdapters::Column.new(
            "tableoid",
            cast_type,
            nil,
            sql_type_metadata,
            true,
            nil
          )

          columns_hash["tableoid"] ||= column
        end

        def reinitialize_relation_delegate_cache
          @relation_delegate_cache.each do |klass, delegate|
            mangled_name = klass.name.gsub("::", "_")
            remove_const(mangled_name) if const_defined?(mangled_name, false)
          end
          initialize_relation_delegate_cache
        end

      end
    end
  end
end
