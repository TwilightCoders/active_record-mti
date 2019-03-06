Array.class_eval do

  unless instance_method(:join).parameters.last&.first == :block
    alias_method :join_original, :join
    def join(separator=$,)
      if block_given?
        inject(String.new) do |collector, item|
          collector << yield(item).to_s + separator
        end.chomp(separator)
      else
        join_original(separator)
      end
    end
  end

end
