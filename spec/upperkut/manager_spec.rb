require 'spec_helper'
require 'upperkut/manager'

module Upperkut
  RSpec.describe Manager do
    class DummyWorker
      include Upperkut::Worker

      def perform(_events)
      end
    end

    describe '#initialize' do
      it 'initialize and instance correct attributes' do
        manager = Manager.new(
          worker: 'Upperkut::DummyWorker',
          concurrency: 24
        )

        expect(manager.stopped).to be_falsey
        expect(manager.concurrency).to eq 24
        expect(manager.worker).to eq Upperkut::DummyWorker
        expect(manager.logger).to be_instance_of Logger
      end
    end
  end
end
