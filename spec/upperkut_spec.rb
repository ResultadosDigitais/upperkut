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
    end
  end

  describe '#server_middlewares' do
    let(:config) { Upperkut::Configuration.default }

    context 'when block is given' do
      it 'yields the current server middlewares configuration and return it' do
        config.server_middlewares do |chain|
          expect(chain).to be_an(Upperkut::Middleware::Chain)
          chain.add MyMiddleware
        end
        expect(config.server_middlewares.items).to eq([MyMiddleware])
      end
    end

    context 'when no block is given' do
      it 'returns memoized server middlewares with current configuration' do
        server_middlewares = config.server_middlewares
        expect(server_middlewares).to eq(config.server_middlewares)
        expect(server_middlewares).to be_an(Upperkut::Middleware::Chain)
        expect(server_middlewares.items).to eq([])
      end
    end
  end

  describe '#client_middlewares' do
    let(:config) { Upperkut::Configuration.default }

    context 'when block is given' do
      it 'yields the current client middlewares configuration and return it' do
        config.client_middlewares do |chain|
          expect(chain).to be_an(Upperkut::Middleware::Chain)
          chain.add MyMiddleware
        end
        expect(config.client_middlewares.items).to eq([MyMiddleware])
      end
    end

    context 'when no block is given' do
      it 'returns memoized client middlewares with current configuration' do
        client_middlewares = config.client_middlewares
        expect(client_middlewares).to eq(config.client_middlewares)
        expect(client_middlewares).to be_an(Upperkut::Middleware::Chain)
        expect(client_middlewares.items).to eq([])
      end
    end
  end
end
