require 'active_support/concern'

module ActiveRecord
  # == Multi-Table ActiveRecord::MTI
  module MTI
    module Registry

      def self.[]=(klass, tableoid)
        ActiveRecord::MTI.logger.debug "Adding #{klass} to MTI list with #{tableoid.to_s}"
        tableoids[klass] = tableoid
      end

      def self.find_mti_class(tableoid)
        tableoids.key(tableoid)
      end

      def self.tableoid?(klass)
        tableoids[klass]
      end

      private

      cattr_accessor :tableoids do
        { ActiveRecord::Base => false }
      end

    end
  end
end
