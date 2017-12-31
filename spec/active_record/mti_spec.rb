require 'spec_helper'

describe ActiveRecord::MTI do
  describe "#child_tables" do
    it "returns an array of child tables" do
      # Sort the tables by name to not depend on the order
      child_tables = ActiveRecord::MTI.child_tables.sort_by(&:name)

      expect(child_tables[0].name).to eq('admin/hackers')
      expect(child_tables[0].parent_table_name).to eq('admins')

      expect(child_tables[1].name).to eq('admins')
      expect(child_tables[1].parent_table_name).to eq('users')

      expect(child_tables[2].name).to eq('vehicles/trucks')
      expect(child_tables[2].parent_table_name).to eq('vehicles')
    end
  end

  describe "#parent_tables" do
    it "returns an array of child tables" do
      # Sort the tables by name to not depend on the order
      parent_tables = ActiveRecord::MTI.parent_tables.sort_by(&:name)

      expect(parent_tables[0].name).to eq('admins')
      expect(parent_tables[1].name).to eq('users')
      expect(parent_tables[2].name).to eq('vehicles')
    end
  end
end
