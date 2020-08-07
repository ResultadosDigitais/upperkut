require 'spec_helper'
require 'upperkut/strategies/priority_queue'
require 'time'

module Upperkut
  module Strategies
    RSpec.describe PriorityQueue do
      # DummyWorker class to use in tests
      class DummyWorker
        include Upperkut::Worker

        setup_upperkut do |config|
          config.strategy = strategy
        end
      end

      subject(:strategy) do
        options = {
          priority_key: lambda { |item| item.body['tenant_id'] }
        }

        described_class.new(DummyWorker, options)
      end

      before do
        strategy.clear
      end

      describe '#push_items' do
        it 'avoids contiguous priority keys' do
          strategy.push_items([
            {'tenant_id' => 1, 'some_text' => 'item 1.1'},
            {'tenant_id' => 1, 'some_text' => 'item 1.2'},
          ])

          strategy.push_items([
            {'tenant_id' => 2, 'some_text' => 'item 2.1'},
            {'tenant_id' => 2, 'some_text' => 'item 2.2'},
          ])

          strategy.push_items([
            {'tenant_id' => 3, 'some_text' => 'item 3.1'},
            {'tenant_id' => 3, 'some_text' => 'item 3.2'},
          ])

          items = strategy.fetch_items.map(&:body)

          expect(items).to eq([
            {'tenant_id' => 1, 'some_text' => 'item 1.1'},
            {'tenant_id' => 2, 'some_text' => 'item 2.1'},
            {'tenant_id' => 3, 'some_text' => 'item 3.1'},
            {'tenant_id' => 1, 'some_text' => 'item 1.2'},
            {'tenant_id' => 2, 'some_text' => 'item 2.2'},
            {'tenant_id' => 3, 'some_text' => 'item 3.2'},
          ])
        end
      end

      describe '#clear' do
        it 'deletes the queue' do
          strategy.push_items(['tenant_id' => 1, 'event' => 'open'])

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
        it 'returns the number of items to be processed' do
          strategy.push_items([
            {'tenant_id' => 1, 'some_text' => 'item 1.1'},
            {'tenant_id' => 1, 'some_text' => 'item 1.2'},
            {'tenant_id' => 2, 'some_text' => 'item 2.1'},
            {'tenant_id' => 2, 'some_text' => 'item 2.2'},
            {'tenant_id' => 3, 'some_text' => 'item 3.1'},
            {'tenant_id' => 3, 'some_text' => 'item 3.2'},
          ])

          expect(strategy.metrics['size']).to eq(6)
        end
      end
    end
  end
end
