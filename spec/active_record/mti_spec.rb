require 'spec_helper'

require 'pry'

describe ActiveRecord::MTI do

  before(:all) do
    user = User.create(email: 'foo@bar.baz')
    admin = Admin.create(email: 'foo@bar.baz', god_powers: 3)
  end

  it 'casts properly' do
    user = User.first

    expect(user.tableoid).to eq(User.table_name)
  end

  describe 'has the correct count for' do

    it 'parents' do
      users = User.all
      binding.pry
      expect(users.count).to be(2)

    end

    it 'children' do
      admins = Admin.all

      expect(admins.count).to be(1)
    end
  end

end
