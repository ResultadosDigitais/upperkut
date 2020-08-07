require 'spec_helper'
require 'upperkut/item'

module Upperkut
  RSpec.describe Item do
    subject(:item) do
      described_class.new(
        id: 'my-unique-id',
        enqueued_at: current_timestamp,
        body: { 'my_property' => 1 },
      )
    end

    let(:current_timestamp) { Time.now.utc.to_i }

    describe '#initialize' do
      context 'when the enqueued at is not informed' do
        let(:current_timestamp) { nil }

        it 'uses the current timestamp as fallback' do
          expect(item.enqueued_at).to be_within(1).of(Time.now.to_i)
        end
      end
    end

    describe '#body' do
      subject(:body) { item.body }

      it { is_expected.to eq({ 'my_property' => 1 }) }
    end

    describe '#enqueued_at' do
      subject { item.enqueued_at }

      it { is_expected.to eq(current_timestamp) }
    end

    describe '#nack' do
      it 'marks a item as acknowledged' do
        expect { item.nack }.to change { item.nacked? }.to(true)
      end
    end

    describe '#nacked?' do
      subject { item.nacked? }

      context 'when the item is not nacked' do
        it { is_expected.to be_falsey }
      end

      context 'when the item is nacked' do
        before { item.nack }

        it { is_expected.to be_truthy }
      end
    end
  end
end

