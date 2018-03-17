require 'spec_helper'

describe ActiveRecord::Inheritance do
  context 'class definition' do
    describe 'for classes that use STI' do
      it "doesn't check inheritance multiple times" do
        Transportation::Military::Vehicle.create(color: :red)
        Transportation::Military::Vehicle.create(color: :blue)
        Transportation::Military::Vehicle.create(color: :green)
        Transportation::Military::Vehicle.create(color: :gold)

        vehicle = Transportation::Military::Vehicle.first
        expect(vehicle.class.name).to eq('Transportation::Military::Vehicle')
        expect(vehicle.color).to eq('red')
      end
    end
  end
end
