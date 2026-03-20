require 'active_record/mti/version'
require 'active_record/mti/railtie' if defined?(Rails::Railtie)

require 'active_record/mti/thread_context'
require 'active_record/mti/table'

module ActiveRecord
  module MTI

    mattr_accessor :oid_class do
      begin
        ActiveModel::Type::Integer
      rescue NameError
        ActiveRecord::Type::Integer
      end
    end

    @mutex = Mutex.new

    def self.child_tables
      @child_tables || @mutex.synchronize { @child_tables ||= load_child_tables }
    end

    def self.parent_tables
      @parent_tables || @mutex.synchronize { @parent_tables ||= load_parent_tables }
    end

    def self.postgresql_version
      @postgresql_version || @mutex.synchronize do
        @postgresql_version ||= begin
          raw = ActiveRecord::Base.connection.execute("SHOW server_version").to_a.first['server_version']
          Gem::Version.new(raw[/[\d.]+/])
        end
      end
    end

    def self.reset!
      @mutex.synchronize do
        @child_tables = nil
        @parent_tables = nil
        @postgresql_version = nil
        @registry = nil
      end
    end

    def self.[](key)
      registry[key]
    end

    def self.[]=(key, value)
      existing = registry[key]
      if existing && !value.nil? && existing != value
        raise "OID #{key} already mapped to #{existing}, cannot reassign to #{value}"
      end
      registry[key] = value
    end

    class << self
      private

      def registry
        @registry ||= {}
      end

      def load_child_tables
        ActiveRecord::Base.connection.execute(SQL_FOR_CHILD_TABLES).to_a.map { |row|
          ChildTable.new(
            row['inhrelid'], row['inhparent'], row['inhseqno'],
            row['oid'], row['name'], row['parent_table_name']
          ).freeze
        }
      end

      def load_parent_tables
        ActiveRecord::Base.connection.execute(SQL_FOR_PARENT_TABLES).to_a.map { |row|
          ParentTable.new(row['oid'], row['name']).freeze
        }
      end
    end

    ChildTable  = Struct.new(:inhrelid, :inhparent, :inhseqno, :oid, :name, :parent_table_name)
    ParentTable = Struct.new(:oid, :name)

    SQL_FOR_CHILD_TABLES = <<~SQL.gsub(/\s+/, " ").strip
      SELECT "pg_inherits".inhrelid, "pg_inherits".inhparent, "pg_inherits".inhseqno,
             "child".oid AS oid, "child".relname AS name, "parent".relname AS parent_table_name
        FROM "pg_inherits"
        JOIN "pg_class" AS "child" ON ("child".oid = "pg_inherits".inhrelid)
        JOIN "pg_class" AS "parent" ON ("parent".oid = "pg_inherits".inhparent)
    SQL

    SQL_FOR_PARENT_TABLES = <<~SQL.gsub(/\s+/, " ").strip
      SELECT DISTINCT("pg_class".oid) AS oid, "pg_class".relname AS name
        FROM "pg_class", "pg_inherits"
        WHERE "pg_class".oid = "pg_inherits".inhparent
    SQL

    private_constant :ChildTable, :ParentTable, :SQL_FOR_CHILD_TABLES, :SQL_FOR_PARENT_TABLES
  end
end
