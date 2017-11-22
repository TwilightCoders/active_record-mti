module ActiveRecord
  # == Multi-Table ActiveRecord::MTI
  module MTI
    module Registry

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

      private

      mattr_accessor :tableoids
      self.tableoids = { ActiveRecord::Base => false }
    end
  end
end
