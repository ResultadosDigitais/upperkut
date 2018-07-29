require 'spec_helper'

module Upperkut
  RSpec.describe Util do
    include Upperkut::Util

    describe '#decode_json_items' do
      context 'when collection has nil values' do
        it 'rejects nil and preserve collection' do
          items = [nil, nil, nil, '{"id":2,"name":"value"}']

          expect(decode_json_items(items)).to eq(
            [
              'id' => 2,
              'name' =>'value'
            ]
          )
        end
      end
    end
  end
end
