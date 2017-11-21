class Hash

  def &(other)
    Hash[(self.keys & other.keys).zip(other.values_at(*(self.keys & other.keys)))]
  end

end
