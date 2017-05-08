require 'active_record'
require 'pry'

class Comment < ::ActiveRecord::Base
  belongs_to :user
  belongs_to :post

end

class Post < ::ActiveRecord::Base
  belongs_to :user
  has_many :comments

end

class User < ::ActiveRecord::Base
  self.inheritance_column = 'tableoid'
  has_many :posts
  has_many :comments

end

class Admin < User
  self.table_name = 'admins'


end
