require 'spec_helper'
require 'upperkut'

RSpec.describe Upperkut::Configuration do
  describe '.default' do
    it 'return an upperkut configuration values as default' do
      default = Upperkut::Configuration.default

      expect(default.batch_size).to eq 1_000
      expect(default.redis). to be_instance_of(Redis)
      expect(default.max_wait).to eq 20
      expect(default.polling_interval).to eq 5
    end
  end
end
