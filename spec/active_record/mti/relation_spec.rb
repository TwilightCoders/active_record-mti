require 'spec_helper'

describe ActiveRecord::MTI::Relation do
  context 'queries' do
    it 'select tableoid' do
      sql = User.all.to_sql
      expect(sql).to match(/SELECT .*, \"users\".\"tableoid\" AS tableoid FROM \"users\"/)
    end
  end
end
