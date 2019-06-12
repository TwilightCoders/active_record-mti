class Post < ::ActiveRecord::Base
  belongs_to :user
  has_many :comments

  has_many :commenters, through: :comments, source: :user
  has_many :admin_commenters, through: :comments, source: :user, class_name: 'Admin'
end
