require 'spec_helper'

describe 'ActiveRecord::MTI Config' do

  context 'can configure' do
    after(:each) do
      ActiveRecord::MTI.reset_configuration
      Manager.reset_table_name
    end
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
      it "##{setting}" do
        ActiveRecord::MTI.configure do |config|
          config.send("#{setting}=", meta[:setting])
        end
        expect(Manager.reset_table_name).to eq(meta[:expectation])
      end
    end
  end

end
