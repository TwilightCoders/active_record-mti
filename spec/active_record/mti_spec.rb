require 'spec_helper'

describe ActiveRecord::MTI do

  context 'helper' do

    describe '#testify' do
      it "returns true for truthy values" do
        expect(ActiveRecord::MTI.testify('f')).to eq(false)
      end
    end

  end

end
