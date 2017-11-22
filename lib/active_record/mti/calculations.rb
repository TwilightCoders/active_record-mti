module ActiveRecord
  module MTI
    module Calculations

      private

      def perform_calculation(*args)
        swap_and_restore_tableoid_cast(true) do
          super
        end
      end

      def swap_and_restore_tableoid_cast(value)
        orignal_value = Thread.current['skip_tableoid_cast']
        Thread.current['skip_tableoid_cast'] = value
        return_value = yield if block_given?
        Thread.current['skip_tableoid_cast'] = orignal_value
        return return_value
      end

    end
  end
end
