module ActiveRecord
  # == Multi-Table Inheritance
  module MTI
    module Inheritance
      def self.prepended(subclass)
        subclass.extend(ClassMethods)
        class << subclass
          attr_reader :mti_type_column
          attr_reader :tableoid_column
        end
      end

      module ClassMethods
        def has_tableoid_column?
          tableoid_column != false
        end

        def inherited(subclass)
          super
          subclass.using_multi_table_inheritance?
        end

        def uses_mti(*_args)
          warn 'DEPRECATED - `uses_mti` is no longer needed (nor has any effect)'
        end

        def using_multi_table_inheritance?
          mti = ActiveRecord::MTI::Registry.tableoid?(self)
          return (mti != false) unless mti.nil?

          if (mti = check_inheritance_of(@table_name))
            mti = if self != base_class && table_name == base_class.table_name
                    false
                  else
                    detect_tableoid(table_name)
                  end
          end

          ActiveRecord::MTI::Registry[self] = mti

          descendants.each(&:using_multi_table_inheritance?)

          mti && mti != false
        end

        private

        def check_inheritance_of(table_name, table_schema = 'public')
          ActiveRecord::MTI.logger.debug("Trying to check inheritance of table with no table name (#{self})") && (return nil) unless table_name
          ActiveRecord::MTI.logger.debug "Checking inheritance for #{table_schema}.#{table_name}"

          result = connection.execute <<-SQL
            SELECT EXISTS (
              SELECT 1
                FROM pg_catalog.pg_inherits       AS i
                  JOIN information_schema.tables  AS t ON t.table_schema = '#{table_schema}' AND t.table_name = '#{table_name}'
                  LEFT JOIN pg_catalog.pg_rewrite AS r ON r.ev_class     = t.table_name::regclass::oid
                  LEFT JOIN pg_catalog.pg_depend  AS d ON d.objid        = r.oid
                  LEFT JOIN pg_catalog.pg_class   AS c ON c.oid          = d.refobjid
                WHERE i.inhrelid  = COALESCE(c.relname, t.table_name)::regclass::oid
                  OR i.inhparent = COALESCE(c.relname, t.table_name)::regclass::oid
            ) AS uses_inheritance;
          SQL

          ActiveRecord::MTI.testify(result.try(:first)['uses_inheritance']) == true
        end

        def detect_tableoid(table_name, table_schema = 'public')
          tableoid_query = connection.execute(<<-SQL
            SELECT 1 AS has_tableoid_column, t.table_name::regclass::oid as tableoid
              FROM   pg_catalog.pg_attribute
              JOIN   information_schema.tables t ON t.table_schema = '#{table_schema}' AND t.table_name = '#{table_name}'
              WHERE  attrelid = t.table_name::regclass
              AND    attname  = 'tableoid'
              AND    NOT attisdropped;
          SQL
                                             ).first

          tableoid = tableoid_query.try(:[], 'tableoid') || false
          @tableoid_column = ActiveRecord::MTI.testify(tableoid_query.try(:[], 'has_tableoid_column'))

          @mti_type_column = if has_tableoid_column?
            ActiveRecord::MTI.logger.debug "#{table_schema}.#{table_name} has tableoid column! (#{tableoid})"

            arel_table[:tableoid]
          end

          tableoid
        end

        # Called by +instantiate+ to decide which class to use for a new
        # record instance. For single-table inheritance, we check the record
        # for a +type+ column and return the corresponding class.
        def discriminate_class_for_record(record)
          if using_multi_table_inheritance?
            ActiveRecord::MTI::Registry.find_mti_class(record['tableoid']) || self
          else
            super
          end
        end

        # Type condition only applies if it's STI, otherwise it's
        # done for free by querying the inherited table in MTI
        def type_condition(table = arel_table)
          super unless using_multi_table_inheritance?
        end
      end
    end
  end
end
