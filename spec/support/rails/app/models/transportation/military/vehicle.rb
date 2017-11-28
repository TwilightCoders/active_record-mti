module Transportation
  module Military
    class Vehicle < ::Transportation::Vehicle
      self.inheritance_column = 'type'
    end
  end
end
