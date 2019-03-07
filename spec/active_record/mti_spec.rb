require 'spec_helper'

describe ActiveRecord::MTI do

  describe "#child_tables" do
    it "returns an array of child tables" do
      # Sort the tables by name to not depend on the order
      child_tables = ActiveRecord::MTI.child_tables.sort_by(&:name)

      [
        {name: 'admin/fakes', parent: 'user/admins'},
        {name: 'user/admin/hackers', parent: 'user/admins'},
        {name: 'user/admins', parent: 'users'},
        {name: 'user/developers', parent: 'users'}
      ].each_with_index do |table, i|
        expect(child_tables[i].name).to eq(table[:name])
        expect(child_tables[i].parent_table_name).to eq(table[:parent])
      end
    end
  end

  describe "#parent_tables" do
    it "returns an array of child tables" do
      # Sort the tables by name to not depend on the order
      parent_tables = ActiveRecord::MTI.parent_tables.sort_by(&:name)

      expect(parent_tables[0].name).to eq('user/admins')
      expect(parent_tables[1].name).to eq('users')
      expect(parent_tables[2].name).to eq('vehicles')
    end
  end

  describe "#parent_tables" do
    it "returns an array of child tables" do
      FakeAdmin = Class.new(Admin) do
        self.table_name = "meh"
      end

      puts FakeAdmin.mti_table
      expect(FakeAdmin).to receive(:reset_mti_information).at_least(:once).and_call_original
      FakeAdmin.table_name = "admin/fakes"
    end
  end
end
