require 'spec_helper'

describe ActiveRecord::MTI::Table do
  {
    Admin => {
      description: "with set table_name",
      table_name: 'admins'
    },
    Developer => {
      description: "with unset table_name",
      table_name: 'developers'
    },
    SuperAdmin => {
      description: "mti branch with sti leaf",
      table_name: 'admins'
    }
  }.each do |model, meta|
    context meta[:description] do
      it 'finds mti_table' do
        binding.pry
        expect(ActiveRecord::MTI::Table.find(model)).to eq(::ActiveRecord::MTI.child_tables.find(name: model.table_name))
      end
    end
  end
end
