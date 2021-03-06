require 'spec_helper'
require 'support/in_memory_strategy'
require 'upperkut/processor'

module Upperkut
  RSpec.describe Processor do
    subject(:processor) { described_class.new(worker, logger) }

    let(:strategy) { worker.strategy }
    let(:worker) { DummyWorker }
    let(:logger) { Logger.new(nil) }

    class DummyWorker
      include Worker

      setup_upperkut do |config|
        config.strategy = InMemoryStrategy.new
      end

      def perform(_items); end
    end

    class SmarterWorker < DummyWorker
      def handle_error(_exception, _items); end
    end

    around do |example|
      worker.clear
      example.run
      worker.clear
    end

    describe '#process' do
      before do
        allow_any_instance_of(worker).to receive(:perform) do |_instance, items|
          items.select { |item| item.body['event'] == 'will_ack' }
        end
      end

      it 'acknowledges performed and not-acknowledged items' do
        item_1 = { 'id' => '1', 'event' => 'open' }
        item_2 = Item.new(id: '1', body: { 'id' => '2', 'event' => 'will_ack' })
        worker.push_items([ item_1, item_2 ])

        item_2.nack

        expect { processor.process }.to change { strategy.acked }.to([
          an_object_having_attributes(body: item_1)
        ])
      end

      context 'when there is no items to process' do
        before do
          allow(worker).to receive(:fetch_items).and_return([])
        end

        it 'does not call the worker' do
          expect(worker).not_to receive(:perform)
        end
      end

      context 'when something goes wrong while fetching items' do
        let(:logger) { spy('logger') }

        before do
          allow(worker).to receive(:fetch_items).and_raise(ArgumentError)
        end

        it 'it logs correctly' do
          expect { processor.process }.to raise_error(ArgumentError)

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
          allow_any_instance_of(worker).to receive(:perform) do |_instance, items|
            items.select { |item| item.body['event'] == 'will_nack' }.each(&:nack)
            raise ArgumentError
          end
        end

        it 'mark items as not-acknowledged' do
          item_1 = { 'id' => '1', 'event' => 'open' }
          item_2 = { 'id' => '2', 'event' => 'will_nack' }
          worker.push_items([ item_1, item_2 ])

          expect { processor.process }.to change { strategy.nacked }.to([
            an_object_having_attributes(body: item_1),
            an_object_having_attributes(body: item_2)
          ]).and raise_error(ArgumentError)
        end

        context 'when client implements handle_error method' do
          let(:worker) { SmarterWorker }

          it 'calls .handle_error method' do
            item = { 'id' => '1', 'event' => 'open' }
            worker.push_items(item)

            expect_any_instance_of(worker).to receive(:handle_error)

            expect { processor.process }.not_to raise_error(ArgumentError)
          end
        end

        context 'when client doesnt implement handle_error method' do
          it 'requeue_item' do
            item = { 'id' => '1', 'event' => 'open' }
            worker.push_items(item)

            expect(worker.metrics['size']).to eq 1

            expect { processor.process }.to raise_error(ArgumentError)
            expect(worker.metrics['size']).to eq 1
          end

          it 'keeps the same latency' do
            item = Item.new(id: '1', body: { 'id' => '1', 'event' => 'open' }, enqueued_at: 2)
            worker.push_items(item)

            expect {
              processor.process rescue nil
            }.not_to change { worker.metrics['latency'].to_i }
          end
        end
      end
    end

    describe '#blocking_process' do
      before do
        allow(worker.strategy).to receive(:fetch_items).and_call_original
      end

      context 'when it is stopped' do
        it 'stop processing' do
          processor.stop
          expect(processor.blocking_process).to be_nil
        end
      end

      it 'processes only when the strategy decides to' do
        begin
          Timeout::timeout(0.1) do
            processor.blocking_process
          end
        rescue Timeout::Error
        end

        expect(worker.strategy).to have_received(:fetch_items).at_least(1)
      end

      context 'when the strategy decides not to process' do
        before do
          allow(worker.strategy).to receive(:process?).and_return(false)
        end

        it 'sleeps for a while' do
          begin
            Timeout::timeout(0.1) do
              processor.blocking_process
            end
          rescue Timeout::Error
          end

          expect(worker.strategy).not_to have_received(:fetch_items)
        end
      end
    end
  end
end
