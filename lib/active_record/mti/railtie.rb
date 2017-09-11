require 'rails/railtie'

module ActiveRecord
  module MTI
    class Railtie < Rails::Railtie
      initializer 'active_record-mti.load' do |_app|
        ActiveRecord::MTI.logger.info "ActiveRecord::MTI railtie initializer"
        ActiveSupport.on_load(:active_record) do
          ActiveRecord::MTI.load
        end
      end
    end
  end
end

