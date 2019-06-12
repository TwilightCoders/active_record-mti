class Thread
  def self.currently(key, value=true)
    __currently_org__, Thread.current[key] = Thread.current[key], value
    yield if block_given?
  ensure
    Thread.current[key] = __currently_org__
  end

  def self.currently?(key, value=true)
    if Thread.current[key] == value
      block_given? ? yield : true
    end
  end
end
