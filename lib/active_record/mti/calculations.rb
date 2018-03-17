module ActiveRecord
  module MTI
    module Calculations
      private

      def perform_calculation(*)
        Thread.reverb(:skip_tableoid_cast, true) do
          super
        end
      end
    end
  end
end
