require 'spec_helper'

describe ActiveRecord::MTI::CoreExtension do

  context "models that use MTI" do
    {
      Admin => {
        description: "with set table_name",
        table_name: 'user/admins'
      },
      Developer => {
        description: "with unset table_name",
        table_name: 'user/developers'
      },
      SuperAdmin => {
        description: "MTI branch with STI leaf",
        table_name: 'user/admins'
      }
    }.each do |model, meta|
      context meta[:description] do
        let!(:user) { User.create(email: 'foo@bar.baz') }
        let!(:object) { model.create(email: 'foo2@bar.baz') }

        it "creates a column even if class doesn't respond to :attribute" do
          allow(model).to receive(:respond_to?).with(:attribute).and_return(false)

          ActiveRecord::MTI[model] = nil

          expect(model.sti_or_mti?).to eq(true)
        end

        it 'infers the table_name correctly' do
          expect(model.table_name).to eql(meta[:table_name])
        end

        it 'casts parent properly' do
          expect(User.first.class).to eq(User)
        end

        describe 'base class querying' do
          # Reenable when MTI can join/union extra columns (natural join?) from child-tables:
          # `users` doesn't have `type`, but `admins` does, and thus needed to descriminate
          # between `SuperAdmin`s

          xit 'casts children properly' do
            users = User.all
            expect(users.select{ |u| u.is_a?(model) }.count).to eql(1)
          end
        end

        describe 'prime class querying' do
          it 'casts children properly' do
            users = model.all
            expect(users.select{ |u| u.is_a?(model) }.count).to eql(1)
          end
        end

        context 'class definition' do

          it "doesn't check inheritance multiple times" do
            # Due to the anonymous class ("god = Class.new(model)") rspec can't properly distinquish
            # between the two classes. So at most 2 times!
            expect(model).to receive(:check_inheritance_of).and_call_original.at_most(2).times

            model.create(email: 'foo@bar.baz')
            model.create(email: 'foo2@bar.baz')
            model.create(email: 'foo24@bar.baz')
            model.create(email: 'foo246@bar.baz')

          end
        end
      end
    end
  end

  context "models that don't use MTI" do
    {
      Post => {
        description: "with set table_name (unnested)",
        table_name: 'posts'
      }
    }.each do |model, meta|
      context meta[:description] do

        it 'infers the table_name correctly' do
          expect(model.table_name).to eql(meta[:table_name])
        end

        context 'class definition' do
          it 'has nil mti_table' do
            expect(model.mti_table).to be_nil
          end
        end
      end
    end
  end

  describe 'a model that mixes MTI and STI' do

    it 'should set the table_name correctly' do

      expect(Transportation::Truck.table_name).to eq("vehicle/trucks")

    end

    describe 'inheritance_column' do
      let!(:vehicle) { Transportation::Vehicle.create(color: :red) }
      let!(:truck) { Transportation::Truck.create(color: :blue, bed_size: 10) }
      let!(:pickup) { Transportation::Pickup.create(color: :silver, bed_size: 10) }

      it 'should set the custom column correctly' do
        expect(truck.type).to eql('Transportation::Truck')
      end

      context 'base class querying' do
        it 'casts children properly' do
          all_vehicles = Transportation::Vehicle.all
          only_trucks = all_vehicles.select { |v| v.is_a?(Transportation::Truck) }
          only_pickups = all_vehicles.select { |v| v.is_a?(Transportation::Pickup) }

          expect(only_trucks.count).to eql(2)
          expect(only_pickups.count).to eql(1)
        end

        xit 'deserializes children with child specific data' do
          my_truck = Transportation::Vehicle.find(truck.id)
          expect(my_truck.bed_size).to eql(10)
        end
      end

      context 'has the correct count for' do
        it 'parents' do
          expect(Transportation::Vehicle.count).to eql(3)
        end

        it 'children' do
          expect(Transportation::Truck.count).to eql(2)
        end
      end

    end
  end
end
