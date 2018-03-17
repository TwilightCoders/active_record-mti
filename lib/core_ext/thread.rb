class Thread
  def self.reverb(verb, value)
    __reverb_org__, Thread.current[verb] = Thread.current[verb], value
    yield if block_given?
  ensure
    Thread.current[verb] = __reverb_org__
  end
end
