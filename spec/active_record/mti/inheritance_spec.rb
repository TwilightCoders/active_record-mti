require 'spec_helper'

describe ActiveRecord::MTI::Inheritance do

  it "creates a column even if class doesn't respond to :attribute" do
    allow(Admin).to receive(:respond_to?).with(:attribute).and_return(false)

    ActiveRecord::MTI::Registry.tableoids[Admin] = nil

    expect(Admin.using_multi_table_inheritance?).to eq(true)
  end

  it "warns of deprication when using old `uses_mti`" do
    expect { Admin.uses_mti }.to output("DEPRECATED - `uses_mti` is no longer needed (nor has any effect)\n").to_stderr
  end

  context 'class definition' do

    describe 'for classes that use MTI' do

      it 'has non-nil mti_type_column' do
        expect(Admin.mti_type_column).to_not be_nil
      end

      it 'has true tableoid_column' do
        expect(Admin.tableoid_column).to eq(true)
      end

      it "doesn't check inheritance multiple times" do
        # Due to the anonymous class ("god = Class.new(Admin)") rspec can't properly distinquish
        # between the two classes. So at most 2 times!
        expect(Admin).to receive(:check_inheritance_of).and_call_original.at_most(2).times

        Admin.create(email: 'foo@bar.baz', god_powers: 3)
        Admin.create(email: 'foo2@bar.baz', god_powers: 3)
        Admin.create(email: 'foo24@bar.baz', god_powers: 3)
        Admin.create(email: 'foo246@bar.baz', god_powers: 3)

      end
    end

    describe "for classes that don't use MTI" do

      it 'has nil tableoid_column' do
        expect(Post.tableoid_column).to be_nil
      end

      it 'has nil mti_type_column' do
        expect(Post.mti_type_column).to be_nil
      end

      it "doesn't check inheritance multiple times" do
        # ActiveRecord::MTI::Inheritance.register(Post, false)
        expect(Post).to receive(:check_inheritance_of).and_call_original.exactly(1).times

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



        end
      end
    end
  end

  describe 'views' do
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
