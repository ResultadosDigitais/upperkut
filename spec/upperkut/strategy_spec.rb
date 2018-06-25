require 'spec_helper'
require 'upperkut/strategy'

module Upperkut
  RSpec.describe 'Strategy' do
    # DummyWorker class to use in tests
    class DummyWorker
      include Upperkut::Worker
    end

    subject(:strategy) { Strategy.new(DummyWorker, Redis.new) }

    before do
      strategy.clear
    end

    describe '.push_items' do
      it 'insert items in the queue' do
        expect do
          strategy.push_items([{ 'event' => 'open' }, { 'event' => 'click' }])
        end.to change { strategy.size }.from(0).to(2)
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
          end.to change { strategy.size }.from(0).to(1)
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

    describe '.clear' do
      it 'deletes the queue' do
        strategy.push_items(['event' => 'open'])
        expect do
          strategy.clear
        end.to change { strategy.size }.from(1).to(0)
      end
    end
  end
end
