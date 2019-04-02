require 'spec_helper'
require 'upperkut'

RSpec.describe Upperkut::Configuration do
  class MyMiddleware
    def call(_worker, _items); end
  end

  describe '.default' do
    it 'return an upperkut configuration values as default' do
      default = Upperkut::Configuration.default

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
