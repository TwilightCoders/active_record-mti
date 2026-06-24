require 'spec_helper'

describe ActiveRecord::MTI::SchemaDumper do
  before(:each) do
    # SchemaMigration.create_table became an instance method in Rails 7.1
    if ActiveRecord::SchemaMigration.respond_to?(:create_table)
      ActiveRecord::SchemaMigration.create_table
    elsif ActiveRecord::SchemaMigration.respond_to?(:new)
      begin
        sm = if ActiveRecord::SchemaMigration.method(:new).arity != 0
               ActiveRecord::SchemaMigration.new(ActiveRecord::Base.connection_pool)
             else
               ActiveRecord::SchemaMigration.new
             end
        sm.create_table if sm.respond_to?(:create_table)
      rescue
        # Schema migration table likely already exists
      end
    end
  end

  let(:hacker_sql) do
    <<~RUBY
      create_table "user/admin/hackers", inherits: 'user/admins' do |t|
    RUBY
  end

  it 'does not dump indexes for child table' do
    stream = StringIO.new
    # Rails 7.2+ SchemaDumper.dump takes a connection pool; earlier versions take a connection.
    target = if ActiveRecord.gem_version >= Gem::Version.new('7.2')
               ActiveRecord::Base.connection_pool
             else
               ActiveRecord::Base.connection
             end
    ActiveRecord::SchemaDumper.dump(target, stream)

    expect(stream.string).to include(hacker_sql)
  end
end
