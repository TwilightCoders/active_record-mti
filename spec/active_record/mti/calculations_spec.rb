require 'spec_helper'

describe ActiveRecord::MTI::Calculations do
  context 'when an exception occurs' do
    it 'does not continue to adversely affect additional queries' do
      Admin.create(email: 'bob')
      expect { Admin.joins(Transportation::Vehicle).count }.to raise_error(RuntimeError)
      expect(Thread.current[:skip_tableoid_cast]).to_not eq(true)
      expect(Admin.count).to eq(1)
    end
  end

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

      context "count calculations" do
        context "when grouped" do

          it "doesn't project tableoid" do
            model.create(email: 'foo@bar.baz')
            model.create(email: 'foo@bar.baz')
            model.create(email: 'foo24@bar.baz')

            grouped_count = model.group(:email).count

            expect(grouped_count['foo24@bar.baz']).to eq(1)
            expect(grouped_count['foo@bar.baz']).to eq(2)
            expect(User.all.count).to eq(4)

          end
        end

        it "count correctly" do

          model.create(email: 'foo@bar.baz')
          model.create(email: 'foo@bar.baz')
          model.create(email: 'foo24@bar.baz')

          expect(model.count(:email)).to eq(3)
          expect(User.all.count).to eq(4)

        end
      end

      context "when grouped" do
        context "with tableoid explicitly" do
          it "projects tableoid in query" do
            sql = model.select(:email, :tableoid).group(:email).to_sql

            expect(sql).to match(/SELECT .*, \"#{meta[:table_name]}\".\"tableoid\" AS tableoid FROM \"#{meta[:table_name]}\"/)

            expect(sql).to match(/GROUP BY .*, \"#{meta[:table_name]}\".\"tableoid\"/)
          end
        end

        context "without tabloid explicit" do
          it "projects tableoid in query" do
            sql = model.select(:email).group(:email, :tableoid).to_sql

            expect(sql).to match(/SELECT .*, \"#{meta[:table_name]}\".\"tableoid\" AS tableoid FROM \"#{meta[:table_name]}\"/)

            expect(sql).to match(/GROUP BY .*, \"#{meta[:table_name]}\".\"tableoid\"/)
          end
        end
      end
    end
  end
end
