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
        items = Item.new('my_property' => 1)
        normalized_items = normalize_items([ items ])

        expect(normalized_items.map(&:body)).to eq(
          [ 'my_property' => 1 ]
        )
      end

      it 'knows how to handle a single Item class' do
        items = Item.new('my_property' => 1)
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
  end
end
