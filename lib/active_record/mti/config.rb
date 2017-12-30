module ActiveRecord
  module MTI
    class << self
      attr_accessor :configuration
    end

    DEFAULT_CONFIG = {
      table_name_nesting: true,
      nesting_seperator: '/',
      singular_parent: true
    }

    def self.reset_configuration
      self.configuration = OpenStruct.new(DEFAULT_CONFIG)
    end

    self.reset_configuration

    def self.configure
      yield(configuration)
    end
  end
end
