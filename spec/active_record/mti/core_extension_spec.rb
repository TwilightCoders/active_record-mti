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
    it "exposes tableoid as an attribute" do
      expect(User.attribute_names).to include("tableoid")
    end

    # tableoid is a system column: it can be read but never written. A column in
    # columns_hash is written by every INSERT once partial inserts are off (the Rails 7+
    # default), so it must stay a virtual attribute.
    it "does not list tableoid among the table's columns" do
      expect(User.column_names).not_to include("tableoid")
    end

    context "with partial inserts off" do
      flag = ActiveRecord::Base.respond_to?(:partial_inserts) ? :partial_inserts : :partial_writes

      around do |example|
        previous = ActiveRecord::Base.public_send(flag)
        ActiveRecord::Base.public_send(:"#{flag}=", false)
        example.run
      ensure
        ActiveRecord::Base.public_send(:"#{flag}=", previous)
      end

      it "creates a record without writing tableoid" do
        user = User.create!(email: 'partial@example.com')
        expect(User.find(user.id).email).to eq('partial@example.com')
      end

      it "finds or creates a record without writing tableoid" do
        user = User.find_or_create_by!(email: 'found@example.com')
        expect(User.find_or_create_by!(email: 'found@example.com').id).to eq(user.id)
      end
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

  # The oid->class registry fills lazily, so a parent query can meet a child row whose class
  # has not registered yet. Discrimination must not depend on that order.
  describe "discrimination with an unregistered child oid" do
    def unregister(klass)
      oid = klass.mti_table.oid
      ActiveRecord::MTI[oid] = nil
      yield oid
    ensure
      ActiveRecord::MTI[oid] = nil
      ActiveRecord::MTI[oid] = klass
    end

    it "resolves the row to its class through the catalog and re-registers it" do
      Admin.create!(email: 'heal@example.com', god_powers: 1)

      unregister(Admin) do |oid|
        expect(User.where(email: 'heal@example.com').first).to be_a(Admin)
        expect(ActiveRecord::MTI[oid]).to eq(Admin)
      end
    end

    it "prefers the class that owns the table over an STI leaf sharing it" do
      Transportation::Truck.create!(color: 'red')

      unregister(Transportation::Truck) do |oid|
        expect(Transportation::Vehicle.where(color: 'red').first).to be_an_instance_of(Transportation::Truck)
        expect(ActiveRecord::MTI[oid]).to eq(Transportation::Truck)
      end
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
