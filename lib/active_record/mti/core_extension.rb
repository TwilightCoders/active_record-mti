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
          @columns_hash&.delete("tableoid") unless @columns_hash&.frozen?
        end

        def reset_column_information
          super.tap { reset_mti_information }
        end

        def tableoid?
          !ThreadContext.active?(:skip_tableoid_cast) && mti?
        end

        def tableoid
          mti_table&.oid
        end

        def mti_table=(value)
          @mti_table = value
          return unless mti_table

          attribute :tableoid, ActiveRecord::MTI.oid_class.new
          ActiveRecord::MTI[mti_table.oid] = self
          prepend_mti_relation
        end

        def table_name=(value)
          super.tap { reset_mti_table if connected? }
        end

        def load_schema!
          super.tap { add_tableoid_column if mti? }
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
          if (mti_class = ::ActiveRecord::MTI[record.delete('tableoid')])
            mti_class.discriminate_class_for_record(record)
          else
            super
          end
        end

        # Rails 7.0+ extracts _load_from_sql and skips discriminate_class_for_record
        # when the inheritance_column is absent. We force the instantiate path
        # when tableoid is present so MTI class discrimination still fires.
        if ActiveRecord.version >= Gem::Version.new('7.0')
          def _load_from_sql(result_set, &block)
            if mti? && result_set.includes_column?('tableoid')
              column_types = result_set.column_types
              column_types = column_types.reject { |k, _| attribute_types.key?(k) } unless column_types.empty?

              ActiveSupport::Notifications.instrumenter.instrument(
                "instantiation.active_record",
                record_count: result_set.length, class_name: name
              ) do
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

          if columns_hash.frozen?
            @columns_hash = columns_hash.merge("tableoid" => col).freeze
          else
            columns_hash["tableoid"] = col
          end
        end

      private

        def prepend_mti_relation
          if defined?(@relation_delegate_cache) && @relation_delegate_cache
            @relation_delegate_cache.each_value { |delegate| delegate.prepend(::ActiveRecord::MTI::Relation) }
          end
        end

        def build_tableoid_column
          field = synthesize_tableoid_field
          arity = connection.method(:new_column_from_field).arity

          if arity == 3 || arity <= -3
            definitions = connection.send(:column_definitions, table_name)
            connection.send(:new_column_from_field, table_name, field, definitions)
          else
            connection.send(:new_column_from_field, table_name, field)
          end
        rescue ActiveRecord::StatementInvalid, ArgumentError => e
          Rails.logger.warn("[active_record-mti] Failed to build tableoid column: #{e.message}") if defined?(Rails.logger) && Rails.logger
          nil
        end

        def synthesize_tableoid_field
          base = ['tableoid', 'oid', nil, false, 26, -1]
          if ActiveRecord.version >= Gem::Version.new('8.0')
            base + [nil, nil, nil, nil]
          elsif ActiveRecord.version >= Gem::Version.new('7.0')
            base + [nil, nil, nil]
          else
            base + [nil, nil]
          end
        end

      end
    end
  end
end
