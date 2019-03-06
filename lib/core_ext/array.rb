Array.class_eval do

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
