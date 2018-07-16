module ActiveRecord

  prepend
  def self.mti?(subclass, table_name)
    # Find MTI Table from table_name
    # Or calculate what _might_ be the MTI table_name
    # And check MTI
    subclass.mti_table ||= reset_mti_table()
    table_name ||= ActiveRecord::MTI.table_name(subclass)
    ActiveRecord::MTI::Table.find(name: table_name)
    # If @table_
  end

  def self.mti!(subclass, mti_table)
    subclass.prepend(::ActiveRecord::MTI::Core)
  end

  module MTI

    def self.compute_table_name(subclass)
      local_config = configuration.merge(subclass.mti_config || {})
    end

    module Core

      def self.prepended(subclass)

        class << subclass
          attr_accessor :mti_config
        end

        subclass.const_get(:ActiveRecord_Relation).tap do |ar_r|
          ar_r.prepend(::ActiveRecord::MTI::Relation)
        end

    ActiveRecord::MTI.add_tableoid_attribute(self)

      end

      module ClassMethods

        def table_name=(value)
          super.tap do |new_table_name|
            mti_config.table_name = new_table_name
          end
        end

        def reset_table_name #:nodoc:
          self.table_name = if abstract_class?
            superclass == Base ? nil : superclass.table_name
          elsif superclass.abstract_class?
            superclass.table_name || compute_table_name
          else
            compute_table_name
          end
        end

        def compute_table_name
          super.tap do |table_name|
            if (mti_table = ActiveRecord.mti?(self, table_name))
              ActiveRecord.mti!(self, mti_table)
            end
          end
        end

        def super_compute_table_name
          base = base_class
          if self == base
            # Nested classes are prefixed with singular parent table name.
            if parent < Base && !parent.abstract_class?
              contained = parent.table_name
              contained = contained.singularize if parent.pluralize_table_names
              contained += '_'
            end

            "#{full_table_name_prefix}#{contained}#{undecorated_table_name(name)}#{full_table_name_suffix}"
          else
            # STI subclasses always use their superclass' table.
            base.table_name
          end
        end

        def table_name
          # Injection Point
          ActiveRecord::MTI::Core.mti?(self, @table_name)
          super
        end

        def configure_mti
          # TODO: Build DSL for configuring MTI

        end

      end

    end
  end
end
