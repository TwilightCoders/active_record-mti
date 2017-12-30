require 'spec_helper'

describe ActiveRecord::MTI::QueryMethods do
  context 'queries' do
    it 'select tableoid' do
      sql = Admin.all.to_sql
      expect(sql).to match(/SELECT .*, \"admins\".\"tableoid\" AS tableoid FROM \"admins\"/)
    end
  end
end
