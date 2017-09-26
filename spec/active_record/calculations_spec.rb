require 'spec_helper'

require 'pry'

describe ActiveRecord::MTI::Calculations do

  context "don't project tableoid on" do
    it "grouping" do

      Admin.create(email: 'foo@bar.baz', god_powers: 3)
      Admin.create(email: 'foo@bar.baz', god_powers: 3)
      Admin.create(email: 'foo24@bar.baz', god_powers: 3)

      expect(Admin.group(:email).to_sql).to_not include('tableoid')

    end

    it "count calculations" do

      Admin.create(email: 'foo@bar.baz', god_powers: 3)
      Admin.create(email: 'foo@bar.baz', god_powers: 3)
      Admin.create(email: 'foo24@bar.baz', god_powers: 3)

      expect(Admin.count(:email)).to eq(3)

    end
  end

  context "projects tableoid" do
    xit "when selecting :tableoid" do

      Admin.select(:email, :tableoid).group(:email).to_sql
    end
  end

end
