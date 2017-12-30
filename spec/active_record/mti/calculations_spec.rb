require 'spec_helper'

describe ActiveRecord::MTI::Calculations do

  {
    Admin => {
      description: "with table_name explicitly set",
      table_name: 'admins'
    },
    Developer => {
      description: "without table_name explicitly set",
      table_name: 'developers'
    }
  }.each do |model, meta|
    context meta[:description] do
      let!(:user) { User.create(email: 'foo@bar.baz') }

      context 'when an exception occurs' do
        it 'does not continue to adversely affect additional queries' do
          model.create(email: 'bob')
          expect{ model.joins(Transportation::Vehicle).count }.to raise_error(RuntimeError)
          expect(Thread.current['skip_tableoid_cast']).to_not eq(true)
          expect(model.count).to eq(1)
        end
      end

      context "don't project tableoid on" do
        it "grouping" do

          model.create(email: 'foo@bar.baz')
          model.create(email: 'foo@bar.baz')
          model.create(email: 'foo24@bar.baz')

          grouped_count = model.group(:email).count

          expect(grouped_count['foo24@bar.baz']).to eq(1)
          expect(grouped_count['foo@bar.baz']).to eq(2)
          expect(User.all.count).to eq(4)

        end

        it "count calculations" do

          model.create(email: 'foo@bar.baz')
          model.create(email: 'foo@bar.baz')
          model.create(email: 'foo24@bar.baz')

          expect(model.count(:email)).to eq(3)
          expect(User.all.count).to eq(4)

        end
      end

      context "projects tableoid" do
        it "and groups tableoid when selecting :tableoid" do
          sql = model.select(:email, :tableoid).group(:email).to_sql

          expect(sql).to match(/SELECT .*, \"#{meta[:table_name]}\".\"tableoid\" AS tableoid FROM \"#{meta[:table_name]}\"/)

          expect(sql).to match(/GROUP BY .*, \"#{meta[:table_name]}\".\"tableoid\"/)
        end

        it "when grouping :tableoid" do
          sql = model.select(:email).group(:email, :tableoid).to_sql

          expect(sql).to match(/SELECT .*, \"#{meta[:table_name]}\".\"tableoid\" AS tableoid FROM \"#{meta[:table_name]}\"/)

          expect(sql).to match(/GROUP BY .*, \"#{meta[:table_name]}\".\"tableoid\"/)
        end
      end
    end
  end
end
