module ActiveRecord
  module MTI
    module Calculations
      private

      def perform_calculation(*)
        org, Thread.current['skip_tableoid_cast'] = Thread.current['skip_tableoid_cast'], true

        super
      ensure
        Thread.current['skip_tableoid_cast'] = org
      end
    end
  end
end
