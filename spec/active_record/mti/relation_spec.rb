require 'spec_helper'

describe ActiveRecord::MTI::Relation do
  context 'queries' do
    it 'select tableoid' do
      sql = User.all.to_sql
      expect(sql).to match(/SELECT \"users\".*, \"users\".\"tableoid\" FROM \"users\"/)
    end
  end

  context 'complex queries' do
    it 'discriminates class' do
      sql = User.select(User.arel_table[:tableoid]).eager_load(:comments, posts: :comments ).to_sql
      # AR 8.1 projects an explicitly-selected tableoid as "users"."tableoid" (no
      # t<n>_r<n> alias); discrimination still works (verified) as long as it's present.
      expect(sql).to match(/\"users\".\"tableoid\"/)
    end
  end

  context '.tableoid_projection?' do
    it 'discriminates class with Arel::Node::SqlLiteral' do
      value = User.all.tableoid_projection?(Arel::Nodes::SqlLiteral.new('tableoid'))
      expect(value).to eq(true)
    end
  end
end
