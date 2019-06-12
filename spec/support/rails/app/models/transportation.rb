module Transportation
  class Vehicle < ActiveRecord::Base
    self.table_name = "vehicles"
  end

  class Truck < Vehicle
    # table_name should be "vehicle/trucks"
  end

  class Pickup < Truck

  end

end
