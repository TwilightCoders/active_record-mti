require 'active_record/mti/version'

require 'active_support/all'

require 'active_record'
require 'active_record/connection_handling'

require 'core_ext/hash'

require 'active_record/mti/registry'
require 'active_record/mti/railtie' if defined?(Rails::Railtie)

module ActiveRecord
  module MTI
    class << self
      attr_writer :logger

      def logger
        @logger ||= Logger.new($stdout).tap do |log|
          log.progname = name
          log.level = Logger::INFO
        end
      end
    end

    def self.testify(value)
      value == true || value == 't' || value == 1 || value == '1'
    end

    def self.child_tables
      @child_tables ||= ActiveRecord::Base.connection.execute(SQL_FOR_CHILD_TABLES).to_a.map do |row|
                          ChildTable.new(*row.values).freeze
                        end.freeze
    end

    def self.parent_tables
      @parent_tables ||= ActiveRecord::Base.connection.execute(SQL_FOR_PARENT_TABLES).to_a.map do |row|
                           ParentTable.new(*row.values).freeze
                         end.freeze
    end

    ChildTable  = Struct.new(:inhrelid, :inhparent, :inhseqno, :oid, :name, :parent_table_name)
    ParentTable = Struct.new(:oid, :name)

    SQL_FOR_CHILD_TABLES = <<-SQL.gsub(/\s+/, " ").strip
      SELECT "pg_inherits".*, "child".oid AS oid, "child".relname AS name, "parent".relname AS parent_table_name
        FROM "pg_inherits"
        JOIN "pg_class" AS "child" ON ("child".oid = "pg_inherits".inhrelid)
        JOIN "pg_class" AS "parent" ON ("parent".oid = "pg_inherits".inhparent)
    SQL

    SQL_FOR_PARENT_TABLES = <<-SQL.gsub(/\s+/, " ").strip
      SELECT DISTINCT("pg_class".oid) AS oid, "pg_class".relname AS name
        FROM "pg_class", "pg_inherits"
        WHERE "pg_class".oid = "pg_inherits".inhparent
    SQL

    private_constant :ChildTable, :ParentTable, :SQL_FOR_CHILD_TABLES, :SQL_FOR_PARENT_TABLES
  end
end
