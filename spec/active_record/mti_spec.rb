require 'spec_helper'

describe ActiveRecord::MTI do
  context 'helper' do
    describe '#testify' do
      it 'returns true for truthy values' do
        expect(ActiveRecord::MTI.testify('f')).to eq(false)
      end
    end

    it 'root has the right value' do
      expect(ActiveRecord::MTI.root).not_to be_nil
    end

    it 'recovers if oid class candidate is not constantizable' do
      ActiveRecord::MTI.oid_class_candidates.unshift('IDontExist')
      expect(ActiveRecord::MTI.find_oid_class).not_to be_nil
    end
  end
end
