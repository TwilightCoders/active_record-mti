require 'spec_helper'

describe 'ActiveRecord::MTI dynamic classes' do

  it 'infers the table_name from superclass not base_class' do
    God = Class.new(Admin)
    Hacker = Class.new(Admin)

    expect(God.table_name).to eql(Admin.table_name)
    expect(Hacker.table_name).to eql('user/admin/hackers')
  end

  it 'infers the table_name when defined dynamically' do

    class Scrub < ActiveRecord::Base
      const_set(:All, Class.new(Scrub) do |klass|
        class_eval <<-AAA
          self.table_name = 'scrubs/all'
        AAA
      end)
    end

    expect(Scrub::All.table_name).to eq('scrubs/all')
  end

end
