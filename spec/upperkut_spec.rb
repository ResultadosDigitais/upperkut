require 'spec_helper'
require 'upperkut'

RSpec.describe Upperkut::Configuration do
  class MyMiddleware
    def call(_worker, _items); end
  end

  describe '.default' do
    it 'return an upperkut configuration values as default' do
      default = Upperkut::Configuration.default

      expect(default.batch_size).to eq 1_000
      expect(default.max_wait).to eq 20
      expect(default.polling_interval).to eq 5

      default.server_middlewares do |chain|
        chain.add MyMiddleware
      end

      default.client_middlewares do |chain|
        chain.add MyMiddleware
      end
      expect(default.server_middlewares.items).to eq([MyMiddleware])
      expect(default.client_middlewares.items).to eq([MyMiddleware])
    end
  end
end
