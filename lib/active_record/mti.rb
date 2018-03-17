require 'active_record/mti/version'
require 'active_record/mti/railtie' if defined?(Rails::Railtie)

require 'active_record/mti/config'
require 'core_ext/thread'

module ActiveRecord
  module MTI

    # Rails likes to make breaking changes in it's minor versions (like 4.1 - 4.2) :P
    mattr_accessor :oid_class

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

    def self.registry
      @registry ||= {}
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

    mattr_accessor :oid_class_candidates

    # Cannot assign default inside block because of rails 4.0
    self.oid_class_candidates = [
      '::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::Integer', # 4.0, 4.1
      '::ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Integer', # 4.2
      '::ActiveRecord::Type::Integer' # 5.0, 5.1
    ]

    def self.find_oid_class
      oid_class_candidates.find(nil) { |klass|
        begin
          klass.constantize
          true
        rescue NameError
          false
        end
      }.constantize
    end

    self.oid_class = self.find_oid_class

    def self.create_registry(klass, sql)
      Registry.new(ActiveRecord::Base.connection.execute(sql).to_a.map do |row|
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
