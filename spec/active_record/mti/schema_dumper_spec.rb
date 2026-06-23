require 'spec_helper'

describe ActiveRecord::MTI::SchemaDumper do
  let(:hacker_sql) do
    <<~RUBY
      create_table "user/admin/hackers", inherits: 'user/admins' do |t|
    RUBY
  end

  it 'does not dump indexes for child table' do
    stream = StringIO.new
    # AR 8.1's SchemaDumper.dump takes a connection pool, not a connection.
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection_pool, stream)

    expect(stream.string).to include(hacker_sql)
  end
end
