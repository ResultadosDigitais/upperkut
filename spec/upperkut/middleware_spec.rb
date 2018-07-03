require 'spec_helper'
require 'upperkut/middleware'

module Upperkut
  RSpec.describe Middleware::Chain do
    class MyMiddleware
      def call(worker, items)
        worker.redis
        yield
        items.count
      end
    end

    describe 'adding and removing' do
      it 'adds middleware' do
        m = Middleware::Chain.new
        m.add(MyMiddleware)

        expect(m.items).to eq [MyMiddleware]
        m.remove(MyMiddleware)
        expect(m.items).to be_empty
      end
    end

    describe '.invoke_middlewares' do
      it 'executes items of the midleware chain' do
        m = Middleware::Chain.new
        m.add(MyMiddleware)
        worker = spy('worker')
        items  = spy('items')
        execution = spy('execution')

        m.invoke(worker, items) do
          execution.execute
        end

        expect(worker).to have_received(:redis)
        expect(items).to have_received(:count)
        expect(execution).to have_received(:execute)
      end
    end
  end
end
