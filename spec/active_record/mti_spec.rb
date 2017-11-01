require 'spec_helper'

require 'pry'

describe ActiveRecord::MTI do

  xit 'returns non-nil value when checking uses_mti?' do
    # Mod = Class.new(User)
    # expect(Mod.uses_mti?).to be(true)
  end

  context 'class definition' do

    describe 'for classes that use MTI' do
      it "doesn't check inheritence multiple times" do
        Admin.instance_variable_set(:@mti_setup, false)
        expect(Admin).to receive(:check_inheritence_of).and_call_original.exactly(1).times

        Admin.create(email: 'foo@bar.baz', god_powers: 3)
        Admin.create(email: 'foo2@bar.baz', god_powers: 3)
        Admin.create(email: 'foo24@bar.baz', god_powers: 3)

      end
    end

    describe "for classes that don't use MTI" do
      it "doesn't check inheritence multiple times" do
        Post.instance_variable_set(:@uses_mti, nil)
        expect(Post).to receive(:check_inheritence_of).and_call_original.exactly(1).times

        Post.create(title: 'foo@bar.baz')
        Post.create(title: 'foo2@bar.baz')
        Post.create(title: 'foo24@bar.baz')

      end
    end

  end

  context 'default inheritance_column model' do
    let!(:user) { User.create(email: 'foo@bar.baz') }
    let!(:admin) { Admin.create(email: 'foo@bar.baz', god_powers: 3) }

    it 'casts properly' do
      user = User.first
      expect(user.class).to eq(User)
    end

    describe 'base class querying' do
      it 'casts children properly' do
        users = User.all
        expect(users.select{ |u| u.is_a?(Admin) }.count).to eql(1)
      end

      xit 'deserializes children with child specific data' do
        my_admin = User.find(admin.id)
        expect(my_admin.god_powers).to eql(3)
      end
    end

    describe 'has the correct count for' do
      it 'parents' do
        users = User.all
        expect(users.count).to eq(2)
      end

      it 'children' do
        admins = Admin.all
        expect(admins.count).to eq(1)
      end
    end

    describe 'dynamic class creation' do
      it 'infers the table_name from superclass not base_class' do
        god = Class.new(Admin)
        expect(god.table_name).to eql(Admin.table_name)
      end
    end
  end


  describe 'views' do
    before(:each) do
      class UserView < User
        self.table_name = "users_all"
      end

      UserView.connection.execute <<-SQL
        CREATE OR REPLACE VIEW "users_all"
        AS #{ User.all.to_sql }
      SQL
    end

    if ActiveRecord::Base.connection.version >= Gem::Version.new('9.4')
      it 'allows creation pass-through' do

        UserView.create(email: 'dale@twilightcoders.net')
      end
    end
  end

  describe 'dynamic class creation' do
    it 'infers the table_name from superclass not base_class' do
      God = Class.new(Admin)

      Hacker = Class.new(Admin) do
        uses_mti
      end

      expect(God.table_name).to eql(Admin.table_name)
      expect(Hacker.table_name).to eql('admin/hackers')
    end
  end

  describe 'custom inheritance_column model' do
    let!(:vehicle) { Transportation::Vehicle.create(color: :red) }
    let!(:truck) { Transportation::Truck.create(color: :blue, bed_size: 10) }

    describe 'inheritance_column' do
      xit 'should set the custom column correctly' do
        expect(vehicle.type).to eql('vehicles')
        expect(truck.type).to eql('trucks')
      end
    end

    describe 'base class querying' do
      it 'casts children properly' do
        expect(Transportation::Vehicle.all.select{ |v| v.is_a?(Transportation::Truck) }.count).to eql(1)
      end

      xit 'deserializes children with child specific data' do
        my_truck = Transportation::Vehicle.find(truck.id)
        expect(my_truck.bed_size).to eql(10)
      end
    end

    describe 'has the correct count for' do
      it 'parents' do
        expect(Transportation::Vehicle.count).to eql(2)
      end

      it 'children' do
        expect(Transportation::Truck.count).to eql(1)
      end
    end
  end

end
