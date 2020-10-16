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
          # This might be "dangerous" if other gems have modified them as well.
          # It might be more prudent to call "inherited" which calls this as a
          # shared injection point, to play nice with other gems. (DeletedAt?)
          reinitialize_relation_delegate_cache

          # ActiveRecord::MTI.registry[mti_table&.oid] = self # maybe follow schema_cache pattern for this stuff
          # connection.mti_cache.clear_table_cache!(table_name)
          # ActiveRecord::MTI.delete(mti_table.oid)
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
          # if defined?(@mti_table)
          #   return if value == @mti_table
          #   reset_column_information if connected?
          # end

          @mti_table = value

          if mti_table
            self.attribute :tableoid, ActiveRecord::MTI.oid_class.new

            # TODO: Use the list to retrieve ActiveRecord_Relation?
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

        # NOTE: 5.0+ only
        def load_schema!
          super.tap do |attributes|
            add_tableoid_column if mti?
          end
        end

        def reset_mti_table
          mti_table_name = defined?(@table_name) ? @table_name : compute_mti_table_name
          # mti_table_name = @table_name || compute_mti_table_name
          self.mti_table = ActiveRecord::MTI::Table.find(self, mti_table_name)
        end

        def compute_table_name
          mti_table_name || superclass.mti_table_name || super
        end

        def compute_mti_table_name
          # contained = (parent_name || '').split('::').join('/') { |part| part.downcase.singularize }
          @effective_class = superclass
          @effective_class = @effective_class.superclass if name =~ /^#{connection.pool.spec.name}::/

          if @effective_class < ::ActiveRecord::Base && !@effective_class.abstract_class?
            contained = @effective_class.table_name
            contained = contained.singularize if @effective_class.pluralize_table_names
            contained += '/'
          end
          "#{full_table_name_prefix}#{contained}#{undecorated_table_name(name)}#{full_table_name_suffix}"
        end

        def full_table_name_prefix #:nodoc:
          if @effective_class.respond_to?(:module_parents)
            (@effective_class.module_parents.detect { |p| p.respond_to?(:table_name_prefix) } || self).table_name_prefix
          else
            (@effective_class.parents.detect { |p| p.respond_to?(:table_name_prefix) } || self).table_name_prefix
          end
        end

        def full_table_name_suffix #:nodoc:
          if @effective_class.respond_to?(:module_parents)
            (@effective_class.module_parents.detect { |p| p.respond_to?(:table_name_prefix) } || self).table_name_suffix
          else
            (@effective_class.parents.detect { |p| p.respond_to?(:table_name_prefix) } || self).table_name_suffix
          end
        end

        # Returns +true+ if this does not need STI type condition. Returns
        # +false+ if STI type condition needs to be applied.
        # def descends_from_active_record?
        #   a = mti?
        #   b = super
        #   c = superclass.respond_to?(:descends_from_active_record?) ? superclass.descends_from_active_record? : true
        #   # !(a || b || c) || !(!b || c) || (a && b && c)
        #   (!a && !b && c) || b
        # end

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

      protected

        def add_tableoid_column
          # missing_columns = (attributes.keys - @columns_hash.keys)
          # [column_name, type, default, notnull, oid, fmod, collation, comment]
          # field = ["tableoid", "integer", nil, false, 23, -1]
          # column = connection.send(:new_column_from_field, table_name, field)
          # Until support for 5.0 is dropped, we need this, because the internal API changed.
          column = ::ActiveRecord::ConnectionAdapters::PostgreSQLColumn.new(
            'tableoid',
            nil,
            23,
            false,
            table_name,
            nil
          )

          columns_hash["tableoid"] ||= column
        end

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
