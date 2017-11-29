module ActiveRecord
  module MTI
    module Registry

      mattr_accessor :tableoids
      self.tableoids = { ActiveRecord::Base => false }

      def self.[]=(klass, tableoid)
        ActiveRecord::MTI.logger.debug "Adding #{klass} to MTI list with #{tableoid}"
        tableoids[klass] = tableoid
      end

      def self.find_mti_class(tableoid)
        tableoids.key(tableoid)
      end

      def self.tableoid?(klass)
        tableoids[klass]
      end

    end
  end
end
