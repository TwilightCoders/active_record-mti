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

      module ClassMethods

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
          ActiveRecord::MTI[mti_table.oid] = nil if mti?
          @mti_table = nil
        end

        def reset_column_information
          super.tap { reset_mti_information }
        end

        def tableoid?
          # Evaluate mti? first: resolving mti_table registers this class in the oid->class
          # map used for discrimination. Gating it behind the transient skip_tableoid_cast flag
          # (set during calculations) would leave a class first touched inside a count/sum
          # unregistered, breaking later parent->child discrimination in an order-dependent
          # way. The boolean result is unchanged.
          mti? && !ThreadContext.active?(:skip_tableoid_cast)
        end

        def tableoid
          mti_table&.oid
        end

        def mti_table=(value)
          @mti_table = value
          return unless mti_table

          # A virtual attribute, never a column: tableoid is a system column that can be read
          # but not written, and every column is written once partial inserts are off.
          attribute :tableoid, ActiveRecord::MTI.oid_class.new
          ActiveRecord::MTI[mti_table.oid] = self
        end

        def table_name=(value)
          super.tap { reset_mti_table if connected? }
        end

        def reset_mti_table
          name = defined?(@table_name) ? @table_name : compute_mti_table_name
          self.mti_table = ActiveRecord::MTI::Table.find(self, name)
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
          # Both the mutable Hash (Rails <= 7.1) and the read-only IndexedRow (7.2+) support
          # #[], so read the oid uniformly. The `mti_class != self` guard terminates the
          # recursion and hands an MTI branch with an STI leaf to super (STI via the type column).
          if (mti_class = mti_class_for_oid(record['tableoid'])) && mti_class != self
            mti_class.discriminate_class_for_record(record)
          else
            super
          end
        end

        # The class a row's tableoid belongs to. The oid->class registry fills lazily (a class
        # registers when it first resolves its mti_table), so a parent query can meet a row whose
        # subclass hasn't registered yet. On a miss, resolve the oid through the catalog to its
        # loaded class — preferring the class that owns the table (its STI base) over an STI
        # leaf sharing it — and cache it, so discrimination doesn't depend on load order.
        def mti_class_for_oid(oid)
          return unless oid
          ::ActiveRecord::MTI[oid] || register_mti_class_for_oid(oid)
        end

      private

        # AR 6.0+ added a homogeneous fast path (instantiate_instance_of) that skips
        # discrimination when the result set lacks the STI inheritance_column. MTI
        # discriminates on `tableoid`, so intercept that fast path and re-route through
        # `instantiate` (which calls discriminate_class_for_record). `klass == self`
        # matches only AR's homogeneous call, so once `instantiate` has specialized the
        # class, re-entry terminates — and an MTI branch with an STI leaf resolves via
        # super. AR 5.x has no fast path (it always discriminates), so feature detection
        # simply skips the hook there. One seam, every version, no reimplementation.
        if ActiveRecord::Base.respond_to?(:instantiate_instance_of, true)
          def instantiate_instance_of(klass, attributes, column_types = {}, &block)
            if klass == self && mti? && (real = mti_class_for_oid(attributes['tableoid'])) &&
               real != klass
              return instantiate(attributes, column_types, &block)
            end
            super
          end
        end

        def register_mti_class_for_oid(oid)
          child = ::ActiveRecord::MTI.child_tables.detect { |t| t.oid.to_s == oid.to_s }
          return unless child

          owning = descendants.select { |d| d.table_name == child.name }
          klass = owning.find { |d| d.superclass.table_name != child.name } || owning.first
          return unless klass

          # Resolving table_name above may itself have registered the class; don't fight it.
          ::ActiveRecord::MTI[oid] || (::ActiveRecord::MTI[oid] = klass)
        end

      end
    end
  end
end
