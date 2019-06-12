module Admins
  class Super < Admin
    validates_presence_of :type
  end
end
