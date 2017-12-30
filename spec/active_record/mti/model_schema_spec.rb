require 'spec_helper'

describe ActiveRecord::MTI::ModelSchema do
  it 'rescues suffix' do
    f = ActiveRecord::ModelSchema::ClassMethods
    allow_any_instance_of(f).to receive(:full_table_name_suffix).and_raise(NoMethodError)
    expect(Admin.full_table_name_suffix).to eq('')
  end
end
