require 'spec_helper'
require 'upperkut/item'

module Upperkut
  RSpec.describe Item do
    subject(:item) do
      described_class.new(
        id: 'my-unique-id',
        enqueued_at: current_timestamp,
        body: { my_property: 1 },
      )
    end

    let(:current_timestamp) { Time.now.utc.to_i }

    it 'allows accessing body properties like a hash' do
      item[:my_another_property] = 2

      expect(item[:my_another_property]).to eq(2)
    end

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

    describe '#to_json' do
      subject { item.to_json }

      it do
        expected_hash = {
          id: 'my-unique-id',
          body: { 'my_property' => 1 },
          enqueued_at: current_timestamp,
        }

        is_expected.to eq(expected_hash.to_json)
      end
    end

    describe '.from_json' do
      subject(:unserialized_item) { described_class.from_json(item_json) }

      let(:item_json) do
        {
          body: { my_property: 1 },
          enqueued_at: current_timestamp,
        }.to_json
      end

      it 'fetches the item body from the json' do
        expect(unserialized_item.body).to eq({ 'my_property' => 1 })
      end

      it 'fetches the item enqueued_at from the json' do
        expect(unserialized_item.enqueued_at).to eq(current_timestamp)
      end
    end
  end
end

