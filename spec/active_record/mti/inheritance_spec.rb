require 'spec_helper'

describe ActiveRecord::MTI::Inheritance do

  context "models that use MTI" do
    {
      Admin => {
        description: "with set table_name",
        table_name: 'admins'
      },
      Developer => {
        description: "with unset table_name",
        table_name: 'developers'
      },
      SuperAdmin => {
        description: "mti branch with sti leaf",
        table_name: 'admins'
      }
    }.each do |model, meta|
      context meta[:description] do
        let!(:user) { User.create(email: 'foo@bar.baz') }
        let!(:object) { model.create(email: 'foo2@bar.baz') }

        it "creates a column even if class doesn't respond to :attribute" do
          allow(model).to receive(:respond_to?).with(:attribute).and_return(false)

          ActiveRecord::MTI.registry[model] = nil

          expect(model.sti_or_mti?).to eq(true)
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

        describe 'prime class querying' do
          it 'casts children properly' do
            users = model.all
            # binding.pry
            expect(users.select{ |u| u.is_a?(model) }.count).to eql(1)
          end
        end

        context 'class definition' do

          it 'has non-nil mti_table' do
            expect(model.mti_table).to_not be_nil
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
          it 'has nil mti_table' do
            expect(model.mti_table).to be_nil
          end
        end
      end
    end
  end

  describe 'custom inheritance_column model' do
    let!(:vehicle) { Transportation::Vehicle.create(color: :red) }
    let!(:truck) { Transportation::Truck.create(color: :blue, bed_size: 10) }

    describe 'inheritance_column' do
      it 'should set the custom column correctly' do
        expect(truck.type).to eql('Transportation::Truck')
      end
    end

    describe 'base class querying' do
      it 'casts children properly' do
        expect(Transportation::Vehicle.all.select { |v| v.is_a?(Transportation::Truck) }.count).to eql(1)
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
