require 'spec_helper'
require 'upperkut/core_ext'
require 'upperkut'

RSpec.describe 'Core extensions' do
  describe 'String#constantize' do
    it { expect("Upperkut".constantize).to eq(Upperkut) }
  end
end
