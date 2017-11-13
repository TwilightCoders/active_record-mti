require 'spec_helper'

describe ActiveRecord::MTI::Calculations do

  context "don't project tableoid on" do
    it "grouping" do

      Admin.create(email: 'foo@bar.baz', god_powers: 3)
      Admin.create(email: 'foo@bar.baz', god_powers: 3)
      Admin.create(email: 'foo24@bar.baz', god_powers: 3)

      grouped_count = Admin.group(:email).count

      expect(grouped_count['foo24@bar.baz']).to eq(1)
      expect(grouped_count['foo@bar.baz']).to eq(2)

    end

    it "count calculations" do

      Admin.create(email: 'foo@bar.baz', god_powers: 3)
      Admin.create(email: 'foo@bar.baz', god_powers: 3)
      Admin.create(email: 'foo24@bar.baz', god_powers: 3)

      expect(Admin.count(:email)).to eq(3)

    end
  end

  context "projects tableoid" do
    it "and groups tableoid when selecting :tableoid" do
      sql = Admin.select(:email, :tableoid).group(:email).to_sql

      expect(sql).to match(/SELECT .*, \"admins\".\"tableoid\" AS tableoid FROM \"admins\"/)

      expect(sql).to match(/GROUP BY .*, \"admins\".\"tableoid\"/)
    end

    it "when grouping :tableoid" do
      sql = Admin.select(:email).group(:email, :tableoid).to_sql

      expect(sql).to match(/SELECT .*, \"admins\".\"tableoid\" AS tableoid FROM \"admins\"/)

      expect(sql).to match(/GROUP BY .*, \"admins\".\"tableoid\"/)
    end
  end

end
