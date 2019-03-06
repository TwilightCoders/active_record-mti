class Hash
  unless method_defined?(:&)
    def &(other)
      Hash[(keys & other.keys).zip(other.values_at(*(keys & other.keys)))]
    end
  end
end
