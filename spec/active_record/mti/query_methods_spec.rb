require 'spec_helper'

describe ActiveRecord::MTI::QueryMethods do
  context 'queries' do
    xit 'select tableoid' do
      sql = User.all.to_sql
      expect(sql).to match(/SELECT .*, \"users\".\"tableoid\" AS tableoid FROM \"users\"/)
    end
  end
end
