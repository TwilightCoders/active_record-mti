module ActiveRecord
  module MTI
    # Thread-local context for MTI operations.
    # Replaces the global Thread monkey-patch in core_ext/thread.rb
    module ThreadContext
      def self.with(key, value = true)
        previous = Thread.current[key]
        Thread.current[key] = value
        yield if block_given?
      ensure
        Thread.current[key] = previous
      end

      def self.active?(key, value = true)
        Thread.current[key] == value
      end
    end
  end
end
