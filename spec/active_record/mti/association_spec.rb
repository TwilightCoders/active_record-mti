require 'spec_helper'

describe ActiveRecord::MTI::Relation do
  context 'associations' do
    it 'selects tableoid' do

      u = User.create(email: 'regular@user.com')
      a = Admin.create(email: 'admin@user.com')

      p = Post.create(user: u)
      3.times do
        Comment.create(post: p, user: u)
      end

      Comment.create(post: p, user: a)

      sql = p.admin_commenters.to_sql
      expect(sql).to match_sql(<<~SQL)
        SELECT "user/admins".*, "user/admins"."tableoid" FROM "user/admins"
      SQL
    end

    it 'discriminates class' do

      u = User.create(email: 'regular@user.com')
      a = Admin.create(email: 'admin@user.com')

      p = Post.create(user: u)
      3.times do
        Comment.create(post: p, user: u)
      end

      Comment.create(post: p, user: a)

      expect(p.commenters.last).to be_an(Admin)
    end

  end
end
