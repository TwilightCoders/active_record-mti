require 'active_record/mti/version'
require 'active_record/mti/railtie' if defined?(Rails::Railtie)

require 'active_record/mti/thread_context'
require 'active_record/mti/table'

module ActiveRecord
  module MTI

    # Rails changed the location of Type::Integer across versions
    mattr_accessor :oid_class do
      begin
        ActiveModel::Type::Integer
      rescue NameError
        ActiveRecord::Type::Integer
      end
    end

    # --- Table discovery from pg_inherits ---

    def self.child_tables
      @child_tables ||= load_child_tables
    end

    def self.parent_tables
      @parent_tables ||= load_parent_tables
    end

    def self.reset!
      @child_tables = nil
      @parent_tables = nil
      @registry = nil
    end

    def self.postgresql_version
      @postgresql_version ||= begin
        raw = ActiveRecord::Base.connection.execute("SHOW server_version").to_a.first['server_version']
        # Strip non-numeric suffixes like "(Homebrew)" or "(Ubuntu)"
        Gem::Version.new(raw[/[\d.]+/])
      end
    end

    # --- OID -> Class registry ---

    def self.[](key)
      registry[key]
    end

    def self.[]=(key, value)
      if self[key] && !value.nil?
        raise "Already assigned OID #{key} to #{self[key]}, cannot reassign to #{value}"
      else
        registry[key] = value
      end
    end

    private

    def self.registry
      @registry ||= {}
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

    def self.load_child_tables
      rows = ActiveRecord::Base.connection.execute(SQL_FOR_CHILD_TABLES).to_a
      rows.map { |row|
        ChildTable.new(
          row['inhrelid'], row['inhparent'], row['inhseqno'],
          row['oid'], row['name'], row['parent_table_name']
        ).freeze
      }
    end

    def self.load_parent_tables
      rows = ActiveRecord::Base.connection.execute(SQL_FOR_PARENT_TABLES).to_a
      rows.map { |row| ParentTable.new(row['oid'], row['name']).freeze }
    end

    private_constant :ChildTable, :ParentTable, :SQL_FOR_CHILD_TABLES, :SQL_FOR_PARENT_TABLES
  end
end
