require 'spec_helper'
require 'upperkut/strategies/scheduled_queue'
require 'time'

module Upperkut
  module Strategies
    RSpec.describe ScheduledQueue do
      # DummyWorker class to use in tests
      class DummyWorker
        include Upperkut::Worker
      end

      subject(:strategy) { described_class.new(DummyWorker) }

      before do
        strategy.clear
      end

      describe '#push_items' do
        describe 'when there is no item to push' do
          it 'returns false' do
            expect( strategy.push_items ).to be(false)
          end

          it 'does not insert items in the queue' do
            expect{ strategy.push_items }.not_to change { strategy.metrics['size'] }
          end
        end

        describe 'when there is 1 item to push' do
          it 'returns true' do
            expect( strategy.push_items({ 'event' => 'open' }) ).to be(true)
          end

          it 'inserts the item in the queue' do
            expect{ strategy.push_items({ 'event' => 'open' }) }.to change { strategy.metrics['size'] }.from(0).to(1)
          end
        end

        describe 'when there is more than 1 item to push' do
          it 'returns true' do
            expect( strategy.push_items([{ 'event' => 'open' }, { 'event' => 'click' }]) ).to be(true)
          end

          it 'inserts the items in the queue' do
            expect{ strategy.push_items([{ 'event' => 'open' }, { 'event' => 'click' }]) }.to change { strategy.metrics['size'] }.from(0).to(2)
          end
        end

        it 'insert items in the queue' do
          expect do
            strategy.push_items([{ 'event' => 'open' }, { 'event' => 'click' }])
          end.to change { strategy.metrics['size'] }.from(0).to(2)
        end
      end

      describe '#fetch_items' do
        context 'when the queue is empty' do
          it 'returns empty array' do
            expect(strategy.fetch_items).to eq([])
          end
        end

        context 'when the queue is not empty' do
          context 'when there are items only to the future' do
            it 'returns empty array' do
              timestamp = Time.new(2200).to_i
              strategy.push_items(
                [{ 'event' => 'open', 'timestamp' => timestamp},
                 { 'event' => 'click', 'timestamp' => timestamp }]
              )
              items = strategy.fetch_items

              expect(items).to eq([])
            end
          end

          context 'when there are items to pull now and in the future' do
            it 'returns only the present items' do
              timestamp = Time.new(2200).to_i
              strategy.push_items(
                [{ 'event' => 'open'},
                 { 'event' => 'click', 'timestamp' => timestamp }]
              )
              items = strategy.fetch_items

              expect(items.count).to eq(1)
            end
          end

          context 'when there are more items to pull now than the batch size' do
            subject(:strategy) { described_class.new(DummyWorker, {batch_size: 2}) }

            it 'returns only the present items, limited to batch size' do
              timestamp = Time.new(2200).to_i
              strategy.push_items(
                [{ 'event' => 'open'},
                { 'event' => 'click'},
                { 'event' => 'read'},
                { 'event' => 'write'},]
              )
              items = strategy.fetch_items

              expect(items.count).to eq(2)
            end
          end

          context 'when there are less items to pull now than the batch size' do
            subject(:strategy) { described_class.new(DummyWorker, {batch_size: 100}) }

            it 'returns all the present items' do
              timestamp = Time.new(2200).to_i
              strategy.push_items(
                [{ 'event' => 'open'},
                { 'event' => 'click'},
                { 'event' => 'read'},
                { 'event' => 'write'},]
              )
              items = strategy.fetch_items

              expect(items.count).to eq(4)
            end
          end
        end
      end

      describe '#clear' do
        it 'deletes the queue' do
          strategy.push_items(['event' => 'open'])
          expect do
            strategy.clear
          end.to change { strategy.metrics['size'] }.from(1).to(0)
        end
      end

      describe '#nack' do
        before do
          travel_to(Time.parse('2015-01-01 00:00:00'))

          strategy.push_items([
            { 'event' => 'open' },
            { 'event' => 'click' }
          ])
        end

        it 'add items back on the queue' do
          items = strategy.fetch_items

          expect { strategy.nack(items) }.to change { strategy.metrics['size'] }.from(0).to(2)
        end
      end

      describe '#metrics' do
        it 'returns correct latency' do
          allow(Time).to receive(:now).and_return(Time.parse('2015-01-01 00:00:00'))
          strategy.push_items('event' => 'open', 'k' => 1)

          allow(Time).to receive(:now).and_return(Time.parse('2015-01-01 00:00:04'))
          strategy.push_items('event' => 'open', 'k' => 1)

          allow(Time).to receive(:now).and_return(Time.parse('2015-01-01 00:00:10'))
          expect(strategy.metrics['latency']).to eq 10.0
        end
      end
    end
  end
end
