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
          !ThreadContext.active?(:skip_tableoid_cast) && mti?
        end

        def tableoid
          mti_table&.oid
        end

        def mti_table=(value)
          @mti_table = value

          if mti_table
            self.attribute :tableoid, ActiveRecord::MTI.oid_class.new

            ActiveRecord::MTI.registry[mti_table.oid] = self

            @relation_delegate_cache.each do |_klass, delegate|
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
          super.tap do
            add_tableoid_column if mti?
          end
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

        # Called by +instantiate+ to decide which class to use for a new
        # record instance. MTI class discrimination happens before STI.
        def discriminate_class_for_record(record)
          if (mti_class = ::ActiveRecord::MTI[record.delete('tableoid')])
            mti_class.discriminate_class_for_record(record)
          else
            super
          end
        end

        # Rails 7.1+ optimizes _load_from_sql to skip discriminate_class_for_record
        # when the inheritance_column isn't in the result set. For MTI, we need
        # discrimination to happen when tableoid is present, so we force the
        # instantiate path.
        if ActiveRecord.version >= Gem::Version.new('7.1')
          def _load_from_sql(result_set, &block)
            if mti? && result_set.includes_column?('tableoid')
              column_types = result_set.column_types
              unless column_types.empty?
                column_types = column_types.reject { |k, _| attribute_types.key?(k) }
              end

              message_bus = ActiveSupport::Notifications.instrumenter
              payload = { record_count: result_set.length, class_name: name }

              message_bus.instrument("instantiation.active_record", payload) do
                result_set.map { |record| instantiate(record, column_types, &block) }
              end
            else
              super
            end
          end
        end

      protected

        def add_tableoid_column
          return if columns_hash.key?("tableoid")

          col = build_tableoid_column
          return unless col

          # Rails 7.0+ freezes columns_hash after load_schema!.
          # We need to replace it with a new hash that includes tableoid.
          if columns_hash.frozen?
            @columns_hash = columns_hash.merge("tableoid" => col).freeze
          else
            columns_hash["tableoid"] = col
          end
        end

        def build_tableoid_column
          field = synthesize_tableoid_field
          factory = connection.method(:new_column_from_field)

          case factory.arity
          when 3
            # Rails 7.1+: (table_name, field, definitions)
            definitions = connection.send(:column_definitions, table_name)
            connection.send(:new_column_from_field, table_name, field, definitions)
          else
            # Rails 5.x - 7.0: (table_name, field)
            connection.send(:new_column_from_field, table_name, field)
          end
        rescue => e
          # If column construction fails, the attribute API registration
          # from mti_table= is still active — queries will still work,
          # we just won't have a columns_hash entry.
          nil
        end

        def synthesize_tableoid_field
          # column_definitions returns arrays whose length grew over Rails versions:
          # Rails 5.x: [name, type, default, notnull, oid, fmod, collation, comment]
          # Rails 7.0: + attgenerated
          # Rails 8.0: + attidentity
          base = ['tableoid', 'oid', nil, false, 26, -1]
          if ActiveRecord.version >= Gem::Version.new('8.0')
            base + [nil, nil, nil, nil]  # collation, comment, identity, generated
          elsif ActiveRecord.version >= Gem::Version.new('7.0')
            base + [nil, nil, nil]       # collation, comment, generated
          else
            base + [nil, nil]            # collation, comment
          end
        end

        def reinitialize_relation_delegate_cache
          @relation_delegate_cache.each do |klass, _delegate|
            mangled_name = klass.name.gsub("::", "_")
            remove_const(mangled_name) if const_defined?(mangled_name, false)
          end
          initialize_relation_delegate_cache
        end

      end
    end
  end
end
