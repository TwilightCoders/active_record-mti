require 'spec_helper'

describe ActiveRecord::MTI::ModelSchema do
  describe "#table_name" do
    it "allows for setting a custom table name using self.table_name="
    it "uses singular_parent_table_name/plural_child_table_name"
    it "uses the table name following Rails' default naming convension"
  end
end
