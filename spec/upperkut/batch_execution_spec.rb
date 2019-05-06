require 'spec_helper'
require 'upperkut/batch_execution'

module Upperkut
  RSpec.describe BatchExecution do
    class SmarterWorker
      include Worker

      def perform(_items); end

      def handle_error(_exception, _items); end
    end

    class DummyWorker
      include Worker

      def perform(_items); end
    end

    around do |example|
      DummyWorker.clear
      SmarterWorker.clear
      example.run
      DummyWorker.clear
      SmarterWorker.clear
    end

    let(:worker) { DummyWorker }
    let(:smarter_worker) { SmarterWorker }
    
    context 'when something goes wrong while processing' do
      context 'when client implements handle_error method' do
        it 'calls .handle_error method' do 
          allow_any_instance_of(smarter_worker).to receive(:perform).and_raise(ArgumentError)
  
          item = { 'id' => '1', 'event' => 'open' }
          smarter_worker.push_items(item)
  
          execution = BatchExecution.new(smarter_worker)
          expect_any_instance_of(smarter_worker).to receive(:handle_error)

          expect { execution.execute }.not_to raise_error(ArgumentError)
        end
      end

      context 'when client doesnt implement handle_error method' do
        it 'requeue_item' do
          allow_any_instance_of(worker).to receive(:perform).and_raise(ArgumentError)
  
          item = { 'id' => '1', 'event' => 'open' }
          worker.push_items(item)
  
          expect(worker.metrics['size']).to eq 1
  
          execution = BatchExecution.new(worker)
          expect { execution.execute }.to raise_error(ArgumentError)
          expect(worker.metrics['size']).to eq 1
        end  
      end
    end
  end
end
