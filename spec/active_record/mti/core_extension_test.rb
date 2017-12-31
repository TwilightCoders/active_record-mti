require 'spec_helper'

describe ActiveRecord::MTI::CoreExtension do
  describe ".child_tables" do
    it "returns a colletion of tables if the model's table has descendants" do
      expect(User.child_tables.size).to eq(1)
      expect(User.child_tables[0].name).to eq('admins')

      expect(Transportation::Vehicle.child_tables.size).to eq(1)
      expect(Transportation::Vehicle.child_tables[0].name).to eq('vehicles/trucks')

      expect(Admin.child_tables.size).to eq(1)
      expect(Admin.child_tables[0].name).to eq('admin/hackers')
    end

    it "returns an empty array if the model's table does not have any descendants" do
      expect(Post.child_tables).to be_empty
      expect(Transportation::Truck.child_tables).to be_empty
      expect(Transportation::Military::Vehicle.child_tables).to be_empty
    end
  end

  describe ".mti_table_as_parent" do
    it "returns a table object if the model's table is a parent of other table" do
      expect(User.mti_table_as_parent).to be_present
      expect(User.mti_table_as_parent.oid).to be_present
      expect(User.mti_table_as_parent.name).to eq('users')

      expect(Transportation::Vehicle.mti_table_as_parent).to be_present
      expect(Transportation::Vehicle.mti_table_as_parent.oid).to be_present
      expect(Transportation::Vehicle.mti_table_as_parent.name).to eq('vehicles')
    end

    it "returns a table object if the model's table is a parent of other table" do
      expect(Post.mti_table_as_parent).to be nil
      expect(Admin.mti_table_as_parent).to be nil
      expect(Transportation::Truck.mti_table_as_parent).to be nil
      expect(Transportation::Military::Vehicle.mti_table_as_parent).to be nil
    end
  end

  describe ".mti_table" do
    it "returns a table object if there is a table for the model" do
      expect(Admin.mti_table).to be_present
      expect(Admin.mti_table.oid).to be_present
      expect(Admin.mti_table.name).to eq('admins')
      expect(Admin.mti_table.parent_table_name).to eq('users')

      expect(Transportation::Truck.mti_table).to be_present
      expect(Transportation::Truck.mti_table.oid).to be_present
      expect(Transportation::Truck.mti_table.name).to eq('vehicles/trucks')
      expect(Transportation::Truck.mti_table.parent_table_name).to eq('vehicles')
    end

    it "returns nil if the model does not have a table" do
      expect(User.mti_table).to be nil
      expect(Post.mti_table).to be nil
      expect(Transportation::Vehicle.mti_table).to be nil
      expect(Transportation::Military::Vehicle.mti_table).to be nil
    end
  end

  describe ".using_sti_or_mti?" do
    it "returns true if the model is a MTI model" do
      expect(Admin).to be_using_sti_or_mti
      expect(Transportation::Truck).to be_using_sti_or_mti
    end

    it "returns true if the model is a STI model that inherites from a MTI model" do
      expect(Transportation::Military::Vehicle).to be_using_sti_or_mti
    end

    it "returns false if the model is a normal AR model" do
      expect(User).not_to be_using_sti_or_mti
      expect(Post).not_to be_using_sti_or_mti
      expect(Transportation::Vehicle).not_to be_using_sti_or_mti
    end
  end
end
