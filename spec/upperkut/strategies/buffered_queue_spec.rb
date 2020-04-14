require 'spec_helper'
require 'upperkut/strategies/buffered_queue'
require 'time'

module Upperkut
  module Strategies
    RSpec.describe BufferedQueue do
      subject(:strategy) { described_class.new(DummyWorker, options) }

      let(:options) { { ack_wait_limit: 60 } }

      # DummyWorker class to use in tests
      class DummyWorker
        include Upperkut::Worker

        setup_upperkut do |config|
          config.strategy = strategy
        end
      end

      before do
        strategy.clear
      end

      describe '#push_items' do
        it 'insert items in the queue' do
          expect do
            strategy.push_items([{ 'event' => 'open' }, { 'event' => 'click' }])
          end.to change { strategy.metrics['size'] }.from(0).to(2)
        end

        it 'insert items in the tail' do
          strategy.push_items([{ 'event' => 'open' }])
          strategy.push_items('event' => 'click')

          items = strategy.fetch_items

          expect(items.last.body).to eq('event' => 'click')
        end

        context 'when items isn\'t a array' do
          it 'inserts item in the queue' do
            expect do
              strategy.push_items('event' => 'open', 'k' => 1)
            end.to change { strategy.metrics['size'] }.from(0).to(1)
          end
        end
      end

      describe '#fetch_items' do
        it 'returns the head items off queue' do
          strategy.push_items([{ 'event' => 'open' }, { 'event' => 'click' }])

          items = strategy.fetch_items.map(&:body)

          expect(items).to eq([{ 'event' => 'open' }, { 'event' => 'click' }])
        end

        it 'fetches old unacknowledged items' do
          items = []

          travel_to(Time.parse('2015-01-01 00:00:00'))
          strategy.push_items({ 'event' => 'open' })
          strategy.push_items({ 'event' => 'open' })
          items << strategy.fetch_items.map(&:body)

          travel_to(Time.parse('2015-01-01 00:00:10'))
          items << strategy.fetch_items.map(&:body)

          travel_to(Time.parse('2015-01-01 00:01:10'))
          items << strategy.fetch_items.map(&:body)

          expect(items).to eq([
            [{ 'event' => 'open' }, { 'event' => 'open' }],
            [],
            [{ 'event' => 'open' }, { 'event' => 'open' }]
          ])
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

      describe '#metrics' do
        it 'returns correct latency' do
          travel_to(Time.parse('2015-01-01 00:00:00'))
          strategy.push_items('event' => 'open', 'k' => 1)

          travel_to(Time.parse('2015-01-01 00:00:04'))
          strategy.push_items('event' => 'open', 'k' => 1)

          travel_to(Time.parse('2015-01-01 00:00:10'))
          expect(strategy.metrics['latency']).to eq 10.0
        end
      end
    end
  end
end
