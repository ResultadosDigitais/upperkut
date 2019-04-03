require 'spec_helper'
require 'upperkut/strategies/base'

module Upperkut
  module Strategies
    RSpec.describe Base do
      subject { described_class.new }

      describe '#push_items' do
        it 'raises NotImplementedError' do
          items = []
          expect { subject.push_items(items) }.to raise_error(NotImplementedError)
        end
      end

      describe '#fetch_items' do
        it 'raises NotImplementedError' do
          batch_size = 5
          expect { subject.fetch_items(batch_size) }.to raise_error(NotImplementedError)
        end
      end

      describe '#clear' do
        it 'raises NotImplementedError' do
          expect { subject.clear }.to raise_error(NotImplementedError)
        end
      end

      describe '#process?' do
        it 'raises NotImplementedError' do
          expect { subject.process? }.to raise_error(NotImplementedError)
        end
      end

      describe '#metrics' do
        it 'raises NotImplementedError' do
          expect { subject.metrics }.to raise_error(NotImplementedError)
        end
      end
    end
  end
end
