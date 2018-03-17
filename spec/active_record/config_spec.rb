require 'spec_helper'

describe 'ActiveRecord::MTI Config' do

  {
    table_name_nesting: {
      setting: false,
      expectation: 'managers'
    },
    nesting_seperator: {
      setting: '_',
      expectation: 'user_managers'
    },
    singular_parent: {
      setting: false,
      expectation: 'users/managers'
    }
  }.each do |setting, meta|
    context "When #{setting} is #{meta[:setting].inspect}" do

      after(:each) do
        ActiveRecord::MTI.reset_configuration
      end

      it "table_name should equal #{meta[:expectation]}" do

        ActiveRecord::MTI.configure do |config|
          config.send("#{setting}=", meta[:setting])
        end
        expect(Manager.reset_table_name).to eq(meta[:expectation])
      end
    end
  end

end
