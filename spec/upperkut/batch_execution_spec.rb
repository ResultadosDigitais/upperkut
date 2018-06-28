require 'spec_helper'
require 'upperkut/batch_execution'

module Upperkut
  RSpec.describe BatchExecution do
    class DummyWorker
      include Worker

      def perform(_items); end
    end

    after do
      DummyWorker.clear
    end

    let(:worker) { DummyWorker }

    context 'when something goes wrong while processing' do
      it 'requeue_item' do
        allow_any_instance_of(worker).to receive(:perform).and_raise

        item = {'id' => '1', 'event' => 'open'}
        worker.push_items(item)

        expect(worker.size).to eq 1

        execution = BatchExecution.new(worker)
        expect { execution.execute }.to raise_error
        expect(worker.size).to eq 1
      end
    end
  end
end
