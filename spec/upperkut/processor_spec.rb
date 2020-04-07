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

    context 'when something goes wrong while fetching items' do
      it 'it logs correctly' do
        allow(DummyWorker).to receive(:fetch_items).and_raise(ArgumentError)

        logger = spy('logger')
        execution = BatchExecution.new(worker, logger)
        expect { execution.execute }.to raise_error(ArgumentError)

        expect(logger).to have_received(:error) do |args|
          expect(args[:action]).to eq(:handle_execution_error)
          expect(args[:ex]).to eq('ArgumentError')
          expect(args[:backtrace]).to be
          expect(args[:item_size]).to eq 0
        end

        expect_any_instance_of(DummyWorker).not_to receive(:push_items)
        expect_any_instance_of(DummyWorker).not_to receive(:handle_error)
      end
    end

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

        it 'keeps the same latency' do
          allow_any_instance_of(worker).to receive(:perform).and_raise(ArgumentError)

          item = Item.new({ 'id' => '1', 'event' => 'open' }, 2)
          worker.push_items(item)

          expect {
            execution = BatchExecution.new(worker)
            execution.execute rescue nil
          }.not_to change { worker.metrics['latency'].to_i }
        end
      end
    end
  end
end
