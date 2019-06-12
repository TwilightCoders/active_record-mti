require 'spec_helper'

describe ActiveRecord::MTI::CoreExtension do

  describe ".mti_table" do
    it "returns a table object if there is a table for the model" do
      expect(User.mti_table).to be_present
      expect(User.mti_table.oid).to be_present
      expect(User.mti_table.name).to eq('users')

      expect(Admin.mti_table).to be_present
      expect(Admin.mti_table.oid).to be_present
      expect(Admin.mti_table.name).to eq('user/admins')
      expect(Admin.mti_table.parent_table_name).to eq('users')

      expect(Transportation::Truck.mti_table).to be_present
      expect(Transportation::Truck.mti_table.oid).to be_present
      expect(Transportation::Truck.mti_table.name).to eq('vehicle/trucks')
      expect(Transportation::Truck.mti_table.parent_table_name).to eq('vehicles')
    end

    it "returns nil if the model does not have a table" do
      expect(Post.mti_table).to be nil
    end
  end

  describe 'model' do
    it "shows tableoid column" do
      expect(User.column_names).to include("tableoid")
    end
  end

  describe '#table_name=' do
    after(:each) { User.table_name = "users" }

    it "resets information" do
      expect(User).to receive(:reset_mti_information).and_call_original.at_most(2).times
      User.table_name = "foobar/users"
    end

    it "retains mti?" do
      User.table_name = "foobar/users"
      User.table_name = "users"
      expect(User.mti?).to eq(true)
    end
  end

  describe ".sti_or_mti?" do
    it "returns true if the model is a MTI model" do
      expect(Admin).to be_sti_or_mti
      expect(Transportation::Truck).to be_sti_or_mti
    end

    it "returns true if the model is a STI model that inherites from a MTI model" do
      expect(Transportation::Pickup).to be_sti_or_mti
    end

    it "returns false if the model is a normal AR model" do
      expect(User).not_to be_sti_or_mti
      expect(Post).not_to be_sti_or_mti
      expect(Transportation::Vehicle).not_to be_sti_or_mti
    end
  end
end
