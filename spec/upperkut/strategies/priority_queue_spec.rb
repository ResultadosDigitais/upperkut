require 'spec_helper'
require 'upperkut/strategies/priority_queue'
require 'time'

module Upperkut
  module Strategies
    RSpec.describe PriorityQueue do
      # DummyWorker class to use in tests
      class DummyWorker
        include Upperkut::Worker
      end

      subject(:strategy) { described_class.new(DummyWorker) }

      before do
        strategy.clear
      end

      describe '.push_items' do
        it 'insert items in the queue' do
          expect do
            strategy.push_items([{ 'event' => 'open' }, { 'event' => 'click' }])
          end.to change { strategy.metrics['size'] }.from(0).to(2)
        end

        it 'insert items in the tail' do
          strategy.push_items([{ 'event' => 'open' }])
          strategy.push_items('event' => 'click')

          items = strategy.fetch_items.collect do |item|
            item['body']
          end

          expect(items.last).to eq('event' => 'click')
        end

        context 'when items isn\'t a array' do
          it 'inserts item in the queue' do
            expect do
              strategy.push_items('event' => 'open', 'k' => 1)
            end.to change { strategy.metrics['size'] }.from(0).to(1)
          end
        end
      end

      describe '.fetch_items' do
        it 'returns the head items off queue' do
          strategy.push_items([{ 'event' => 'open' }, { 'event' => 'click' }])

          items = strategy.fetch_items.collect do |item|
            item['body']
          end

          expect(items).to eq([{ 'event' => 'open' }, { 'event' => 'click' }])
        end
      end

      describe '.latency' do
        it 'returns correct latency' do
          allow(Time).to receive(:now).and_return(Time.parse('2015-01-01 00:00:00'))
          strategy.push_items('event' => 'open', 'k' => 1)

          allow(Time).to receive(:now).and_return(Time.parse('2015-01-01 00:00:04'))
          strategy.push_items('event' => 'open', 'k' => 1)

          allow(Time).to receive(:now).and_return(Time.parse('2015-01-01 00:00:10'))

          expect(strategy.metrics['latency']).to eq 10.0
        end
      end

      describe '.clear' do
        it 'deletes the queue' do
          strategy.push_items(['event' => 'open'])
          expect do
            strategy.clear
          end.to change { strategy.metrics['size'] }.from(1).to(0)
        end
      end
    end
  end
end
