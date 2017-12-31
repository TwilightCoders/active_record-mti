require 'spec_helper'

describe ActiveRecord::MTI::Inheritance do

  context "models that use MTI" do
    {
      Admin => {
        description: "with set table_name (unnested)",
        table_name: 'admins'
      },
      Developer => {
        description: "with unset table_name (unnested)",
        table_name: 'developers'
      },
      Manager => {
        description: "with unset table_name (nested)",
        table_name: 'user/managers'
      }
    }.each do |model, meta|
      context meta[:description] do
        let!(:user) { User.create(email: 'foo@bar.baz') }
        let!(:object) { model.create(email: 'foo2@bar.baz') }

        it "creates a column even if class doesn't respond to :attribute" do
          allow(model).to receive(:respond_to?).with(:attribute).and_return(false)

          ActiveRecord::MTI::Registry.tableoids[model] = nil

          expect(model.using_multi_table_inheritance?).to eq(true)
        end

        it "warns of deprication when using old `uses_mti`" do
          expect { model.uses_mti }.to output("DEPRECATED - `uses_mti` is no longer needed (nor has any effect)\n").to_stderr
        end

        it 'infers the table_name correctly' do
          expect(model.table_name).to eql(meta[:table_name])
        end

        it 'casts parent properly' do
          expect(User.first.class).to eq(User)
        end

        describe 'base class querying' do
          it 'casts children properly' do
            users = User.all
            expect(users.select{ |u| u.is_a?(model) }.count).to eql(1)
          end
        end

        context 'class definition' do

          it 'has non-nil mti_type_column' do
            expect(model.mti_type_column).to_not be_nil
          end

          it 'has true tableoid_column' do
            expect(model.tableoid_column).to eq(true)
          end

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
          it 'has nil tableoid_column' do
            expect(model.tableoid_column).to be_nil
          end

          it 'has nil mti_type_column' do
            expect(model.mti_type_column).to be_nil
          end

          it "doesn't check inheritance multiple times" do
            # ActiveRecord::MTI::Inheritance.register(model, false)
            expect(ActiveRecord::MTI::Inheritance).to receive(:check).with(meta[:table_name]).and_call_original.exactly(1).times

            model.create(title: 'foo@bar.baz')
            model.create(title: 'foo2@bar.baz')
            model.create(title: 'foo24@bar.baz')

          end
        end
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
