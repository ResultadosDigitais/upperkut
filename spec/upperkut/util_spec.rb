require 'spec_helper'

module Upperkut
  RSpec.describe Util do
    include Upperkut::Util

    describe '#normalize_items' do
      it 'transforms hashes into items' do
        items_hash = [{ 'my_property' => 1 }]
        items = normalize_items(items_hash)

        expect(items.map(&:body)).to eq(
          [ 'my_property' => 1 ]
        )
      end

      it 'knows how to handle a single item' do
        items_hash = { 'my_property' => 1 }
        items = normalize_items(items_hash)

        expect(items.map(&:body)).to eq(
          [ 'my_property' => 1 ]
        )
      end

      it 'knows how to handle an Item class' do
        items = Item.new(body: { 'my_property' => 1 })
        normalized_items = normalize_items([ items ])

        expect(normalized_items.map(&:body)).to eq(
          [ 'my_property' => 1 ]
        )
      end

      it 'knows how to handle a single Item class' do
        items = Item.new(body: { 'my_property' => 1 })
        normalized_items = normalize_items(items)

        expect(normalized_items.map(&:body)).to eq(
          [ 'my_property' => 1 ]
        )
      end
    end

    describe '#decode_json_items' do
      context 'when collection has nil values' do
        it 'rejects nil and preserve collection' do
          items_json = [nil, nil, nil, '{"body":{"id":2,"name":"value"}}']
          items = decode_json_items(items_json).map(&:body)

          expect(items).to eq(
            [
              'id' => 2,
              'name' => 'value'
            ]
          )
        end
      end
    end

    describe '#retry_block' do
      before do
        allow(Kernel).to receive(:sleep).and_return(nil)
      end

      it 'retries the block within a limit' do
        invocation_counter = 0
        retry_block(2) { invocation_counter += 1; raise RuntimeError } rescue nil
        expect(invocation_counter).to eq(3)
      end

      it 'waits exponentially to retry' do
        expect(Kernel).to receive(:sleep).with(2 ** 1).ordered
        expect(Kernel).to receive(:sleep).with(2 ** 2).ordered
        expect(Kernel).to receive(:sleep).with(2 ** 3).ordered

        retry_block(3, 2) { raise RuntimeError } rescue nil
      end

      it 'waits exponentially to retry' do
        expect {
          retry_block { raise RuntimeError }
        }.to raise_error(RuntimeError)
      end

      it 'returns the yielded block result' do
        expect(retry_block { 'my-return' }).to eq('my-return')
      end
    end
  end
end
