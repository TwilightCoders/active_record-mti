require 'active_support/concern'

module ActiveRecord
  # == Multi-Table Inheritance
  module MTI
    module Inheritance
      extend ActiveSupport::Concern

      included do
        @@mti_tableoids = {}
        scope :discern_inheritance, -> {

        }
      end

      module ClassMethods

        @uses_mti = nil
        @mti_setup = false
        @mti_type_column = nil

        def uses_mti(custom_table_name = nil, inheritance_column = nil)
          self.inheritance_column = inheritance_column

          @uses_mti = true
          @tableoid_column = nil
        end

        def using_multi_table_inheritance?(klass = self)
          klass.uses_mti?
        end

        def uses_mti?
          inheritance_check = check_inheritance_of(@table_name) unless @mti_setup

          if @uses_mti.nil? && @uses_mti = inheritance_check
            descendants.each do |d|
              d.uses_mti?
            end
          end

          @uses_mti
        end

        def has_tableoid_column?
          @tableoid_column != false
        end

        def mti_type_column
          @mti_type_column
        end

        def mti_type_column=(value)
          @mti_type_column = value
        end

        private

        def check_inheritance_of(table_name)
          ActiveRecord::MTI.logger.debug "Trying to check inheritance of table with no table name (#{self})" unless table_name
          return nil unless table_name

          ActiveRecord::MTI.logger.debug "Checking inheritance for #{table_name}"

          result = connection.execute <<-SQL
            SELECT EXISTS (
              SELECT 1
              FROM      pg_catalog.pg_inherits AS i
              LEFT JOIN pg_catalog.pg_rewrite  AS r    ON r.ev_class = 'public.#{table_name}'::regclass::oid
              LEFT JOIN pg_catalog.pg_depend   AS d    ON d.objid    = r.oid
              LEFT JOIN pg_catalog.pg_class    AS cl_d ON cl_d.oid   = d.refobjid
              WHERE inhrelid  = COALESCE(cl_d.relname, 'public.#{table_name}')::regclass::oid
              OR    inhparent = COALESCE(cl_d.relname, 'public.#{table_name}')::regclass::oid
            ) AS uses_inheritance;
          SQL

          uses_inheritance = ActiveRecord::MTI.testify(result.try(:first)['uses_inheritance'])

          register_tableoid(table_name) if uses_inheritance

          @mti_setup = true
          # Some versions of PSQL return {"?column?"=>"t"}
          # instead of {"exists"=>"t"}, so we're saying screw it,
          # just give me the first value of whatever is returned

          # Ensure a boolean is returned
          return uses_inheritance == true
        end

        def register_tableoid(table_name)

          tableoid_query = connection.execute(<<-SQL
            SELECT '#{table_name}'::regclass::oid AS tableoid, (SELECT EXISTS (
              SELECT 1
              FROM   pg_catalog.pg_attribute
              WHERE  attrelid = '#{table_name}'::regclass
              AND    attname  = 'tableoid'
              AND    NOT attisdropped
            )) AS has_tableoid_column
          SQL
          ).first
          tableoid = tableoid_query['tableoid']
          @tableoid_column = ActiveRecord::MTI.testify(tableoid_query['has_tableoid_column'])

          if (has_tableoid_column?)
            ActiveRecord::MTI.logger.debug "#{table_name} has tableoid column! (#{tableoid})"
            add_tableoid_column
            @mti_type_column = arel_table[:tableoid]
          else
            @mti_type_column = nil
          end

          Inheritance.add_mti(tableoid, self)
        end

        # Called by +instantiate+ to decide which class to use for a new
        # record instance. For single-table inheritance, we check the record
        # for a +type+ column and return the corresponding class.
        def discriminate_class_for_record(record)
          if using_multi_table_inheritance?(base_class)
            find_mti_class(record) || base_class
          elsif using_single_table_inheritance?(record)
            find_sti_class(record[inheritance_column])
          else
            super
          end
        end

        # Search descendants for one who's table_name is equal to the returned tableoid.
        # This indicates the class of the record
        def find_mti_class(record)
          if (has_tableoid_column?)
            Inheritance.find_mti(record['tableoid'])
          else
            self
          end
        end

        # Type condition only applies if it's STI, otherwise it's
        # done for free by querying the inherited table in MTI
        def type_condition(table = arel_table)
          if using_multi_table_inheritance?
            nil
          else
            sti_column = table[inheritance_column]
            sti_names  = ([self] + descendants).map { |model| model.sti_name }

            sti_column.in(sti_names)
          end
        end

        def add_tableoid_column
          if self.respond_to? :attribute
            self.attribute :tableoid, get_integer_oid_class.new
          else
            columns.unshift ActiveRecord::ConnectionAdapters::PostgreSQLColumn.new('tableoid', nil, ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::Integer.new, "oid", false)
          end
        end

        # Rails decided to make a breaking change in it's 4.x series :P
        def get_integer_oid_class
          ::ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Integer
        rescue NameError
          begin
            ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::Integer
          rescue NameError
            ::ActiveModel::Type::Integer
          end
        end

      end

      def self.add_mti(tableoid, klass)
        @@mti_tableoids[tableoid.to_s.to_sym] = klass
      end

      def self.find_mti(tableoid)
        @@mti_tableoids[tableoid.to_s.to_sym]
      end

    end
  end
end
