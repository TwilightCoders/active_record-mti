require 'active_record/mti/version'
require 'active_record/mti/railtie' if defined?(Rails::Railtie)

require 'active_registry'
require 'active_record/mti/table'
require 'core_ext/thread'

module ActiveRecord
  module MTI

    mattr_accessor :oid_class_candidates do
      [
        '::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::Integer', # 4.0, 4.1
        '::ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Integer', # 4.2
        '::ActiveRecord::Type::Integer' # 5.0, 5.1
      ]
    end

    mattr_accessor :oid_class do
      oid_class_candidates.find(nil) { |klass|
        begin
          klass.constantize
          true
        rescue NameError
          false
        end
      }.constantize
    end

    def self.child_tables
      @child_tables ||= create_registry(ChildTable, SQL_FOR_CHILD_TABLES).tap do |r|
        r.index(:name, :oid, :inhparent)
      end
    end

    def self.parent_tables
      @parent_tables ||= create_registry(ParentTable, SQL_FOR_PARENT_TABLES).tap do |r|
        r.index(:oid, :name)
      end
    end

    def self.postgresql_version
      @postgresql_version ||= Gem::Version.new(ActiveRecord::Base.connection.execute(<<-SQL, 'SCHEMA').to_a.first['server_version'])
        SHOW server_version;
      SQL
    end

    def self.[](key)
      registry[key]
    end

    def self.[]=(key, value)
      if (self[key] && value != nil)
        raise "Already assigned"
      else
        registry[key]=value
      end
    end

    def self.add_tableoid_attribute(klass)
      if klass.respond_to? :attribute
        klass.attribute :tableoid, ActiveRecord::MTI.oid_class.new
      else
        new_column = ActiveRecord::ConnectionAdapters::PostgreSQLColumn.new('tableoid', nil, ActiveRecord::MTI.oid_class.new, "oid", false)
        klass.columns.unshift new_column
        klass.columns_hash['tableoid'] = new_column
      end
    end

    private

    def self.registry
      @registry ||= {}
    end

    def self.create_registry(klass, sql)
      ActiveRegistry.new(ActiveRecord::Base.connection.execute(sql).to_a.map do |row|
        klass.new(*row.values).freeze
      end)
    end

    ChildTable  = Struct.new(:inhrelid, :inhparent, :inhseqno, :oid, :name, :parent_table_name)
    ParentTable = Struct.new(:oid, :name)

    SQL_FOR_CHILD_TABLES = (<<-SQL).gsub(/\s+/, " ").strip
      SELECT "pg_inherits".*, "child".oid AS oid, "child".relname AS name, "parent".relname AS parent_table_name
        FROM "pg_inherits"
        JOIN "pg_class" AS "child" ON ("child".oid = "pg_inherits".inhrelid)
        JOIN "pg_class" AS "parent" ON ("parent".oid = "pg_inherits".inhparent)
    SQL

    SQL_FOR_PARENT_TABLES = (<<-SQL).gsub(/\s+/, " ").strip
      SELECT DISTINCT("pg_class".oid) AS oid, "pg_class".relname AS name
        FROM "pg_class", "pg_inherits"
        WHERE "pg_class".oid = "pg_inherits".inhparent
    SQL

    private_constant :ChildTable, :ParentTable, :SQL_FOR_CHILD_TABLES, :SQL_FOR_PARENT_TABLES
  end
end
