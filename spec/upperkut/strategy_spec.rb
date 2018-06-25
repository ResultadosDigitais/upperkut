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
          strategy.push_items(['event' => 'open'])
        end.to change { strategy.size }.from(0).to(1)
      end

      context 'when items isnt a array' do
        it 'inserts item in the queue' do
          expect do
            strategy.push_items('event' => 'open', 'k' => 1)
          end.to change { strategy.size }.from(0).to(1)
        end
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
