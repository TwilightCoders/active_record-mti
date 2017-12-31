module ActiveRecord
  module MTI
    module Querying
      delegate :count_estimate, to: :all
    end
  end
end
