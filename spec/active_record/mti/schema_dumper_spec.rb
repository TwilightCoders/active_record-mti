require 'spec_helper'

describe ActiveRecord::MTI::SchemaDumper do

  before(:each) do
    ActiveRecord::SchemaMigration.create_table
  end

  let(:hacker_sql) {
<<-FOO
  create_table "admin/hackers", inherits: 'admins' do |t|
  end
FOO
  }

  it 'does not dump indexes for child table' do
    stream = StringIO.new
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)

    expect(stream.string).to include(hacker_sql)
  end
end
