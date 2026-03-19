require 'spec_helper'

describe ActiveRecord::MTI do

  describe "#child_tables" do
    it "returns an array of child tables" do
      child_tables = ActiveRecord::MTI.child_tables.sort_by(&:name)
      child_names = child_tables.map(&:name)

      # Original user hierarchy
      expect(child_names).to include('user/admins', 'user/developers', 'user/admin/hackers')

      # Hangar message hierarchy
      expect(child_names).to include(
        'message/user_messages',
        'message/assistant_responses',
        'message/tool_invocations',
        'message/tool_results',
        'message/system_events'
      )

      # Verify parent relationships
      admins = child_tables.detect { |t| t.name == 'user/admins' }
      expect(admins.parent_table_name).to eq('users')

      user_messages = child_tables.detect { |t| t.name == 'message/user_messages' }
      expect(user_messages.parent_table_name).to eq('messages')
    end
  end

  describe "#parent_tables" do
    it "returns an array of parent tables" do
      parent_names = ActiveRecord::MTI.parent_tables.map(&:name).sort

      expect(parent_names).to include('messages', 'user/admins', 'users', 'vehicles')
    end
  end
end
