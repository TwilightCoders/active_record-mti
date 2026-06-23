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
          # Evaluate mti? first: resolving mti_table has the side effect of registering
          # this class in the oid->class map used for discrimination. Gating it behind the
          # transient skip_tableoid_cast flag (set during calculations) would let a class
          # first touched inside a count/sum go unregistered, breaking later parent->child
          # discrimination in an order-dependent way. The boolean result is unchanged.
          mti? && !Thread.currently?(:skip_tableoid_cast)
        end

        def tableoid
          mti_table&.oid
        end

        def mti_table=(value)
          @mti_table = value

          if mti_table
            self.attribute :tableoid, ActiveRecord::MTI.oid_class.new

            ActiveRecord::MTI.registry[mti_table.oid] = self
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

        # AR 8.1's `_load_from_sql` only takes the per-row discriminating `instantiate`
        # path when the result includes the STI `inheritance_column` ("type"); otherwise
        # it fast-paths to a homogeneous set of `self`. MTI discriminates on `tableoid`,
        # so without this, parent→child queries (e.g. an association that resolves to a
        # subclass) silently come back as the base class. We mirror AR's method exactly,
        # only widening the discriminate condition to also fire when `tableoid` is present.
        def _load_from_sql(result_set, &block)
          return super unless mti?
          return [] if result_set.empty?

          column_types = result_set.column_types
          unless column_types.empty?
            column_types = column_types.reject { |k, _| attribute_types.key?(k) }
          end

          discriminate = result_set.includes_column?(inheritance_column) ||
                         result_set.includes_column?('tableoid')

          ActiveSupport::Notifications.instrumenter.instrument(
            "instantiation.active_record",
            record_count: result_set.length, class_name: name
          ) do
            if discriminate
              result_set.indexed_rows.map { |record| instantiate(record, column_types, &block) }
            else
              result_set.indexed_rows.map { |record| instantiate_instance_of(self, record, column_types, &block) }
            end
          end
        end

        def discriminate_class_for_record(record)
          # AR 8.1 hands us an ActiveRecord::Result::IndexedRow (read-only, no #delete),
          # so read the oid via #[] instead of mutating the row. The previous `delete`
          # also terminated the recursion (the recursive call saw a nil tableoid and fell
          # through to `super`); we reproduce that with the `mti_class != self` guard:
          # once the row's tableoid resolves to the current class we hand off to `super`,
          # which is AR's STI discrimination via the `type` column — also how an MTI branch
          # with an STI leaf gets resolved.
          oid = record['tableoid'] if record.respond_to?(:[])
          mti_class = oid && ::ActiveRecord::MTI[oid]

          # The oid->class registry is populated lazily (a side effect of a class first
          # resolving its mti_table), so a parent query can hit a row whose subclass hasn't
          # registered yet. Self-heal: resolve the oid to its loaded class via the catalog,
          # preferring the class that owns the table (its STI base) over any STI leaf that
          # shares it, then cache it. This makes discrimination independent of the order in
          # which classes were first touched.
          if mti_class.nil? && oid && (child = ::ActiveRecord::MTI.child_tables.find(oid: oid))
            owning = descendants.select { |d| d.table_name == child.name }
            mti_class = owning.find { |d| d.superclass.table_name != child.name } || owning.first
            ::ActiveRecord::MTI.registry[oid] = mti_class if mti_class
          end

          if mti_class && mti_class != self
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
