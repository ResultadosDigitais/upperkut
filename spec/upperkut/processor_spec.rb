require 'spec_helper'
require 'upperkut/processor'

module Upperkut
  RSpec.describe Processor do
    subject(:processor) { described_class.new(worker, logger) }

    let(:worker) { DummyWorker }
    let(:logger) { Logger.new(nil) }

    class DummyWorker
      include Worker

      def perform(_items); end
    end

    class SmarterWorker < DummyWorker
      def handle_error(_exception, _items); end
    end

    around do |example|
      DummyWorker.clear
      SmarterWorker.clear
      example.run
      DummyWorker.clear
      SmarterWorker.clear
    end

    context 'when something goes wrong while fetching items' do
      let(:logger) { spy('logger') }

      before do
        allow(worker).to receive(:fetch_items).and_raise(ArgumentError)
      end

      it 'it logs correctly' do
        expect { processor.execute }.to raise_error(ArgumentError)

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
      before do
          allow_any_instance_of(worker).to receive(:perform).and_raise(ArgumentError)
      end

      context 'when client implements handle_error method' do
        let(:worker) { SmarterWorker }

        it 'calls .handle_error method' do
          item = { 'id' => '1', 'event' => 'open' }
          worker.push_items(item)

          expect_any_instance_of(worker).to receive(:handle_error)

          expect { processor.execute }.not_to raise_error(ArgumentError)
        end
      end

      context 'when client doesnt implement handle_error method' do
        it 'requeue_item' do
          item = { 'id' => '1', 'event' => 'open' }
          worker.push_items(item)

          expect(worker.metrics['size']).to eq 1

          expect { processor.execute }.to raise_error(ArgumentError)
          expect(worker.metrics['size']).to eq 1
        end

        it 'keeps the same latency' do
          item = Item.new({ 'id' => '1', 'event' => 'open' }, 2)
          worker.push_items(item)

          expect {
            processor.execute rescue nil
          }.not_to change { worker.metrics['latency'].to_i }
        end
      end
    end
  end
end
