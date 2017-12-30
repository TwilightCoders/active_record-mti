require 'rails/railtie'

module ActiveRecord
  module MTI
    class Railtie < Rails::Railtie
      initializer 'active_record-mti.load' do |_app|
        ActiveRecord::MTI.logger.debug 'active_record-mti.load'
        ActiveSupport.on_load(:active_record) do
          ActiveRecord::MTI.load
        end
      end
    end
  end
end
