require 'spec_helper'

describe 'ActiveRecord::MTI views' do

  before(:each) do
    User.connection.execute <<-SQL
      CREATE OR REPLACE VIEW "users_all"
      AS SELECT * FROM "users"
    SQL

    class UserView < User
      self.table_name = "users_all"
    end

  end

  if ActiveRecord::Base.connection.version >= Gem::Version.new('9.4')
    it 'allows creation pass-through' do

      UserView.create(email: 'dale@twilightcoders.net')
    end
  end

end
