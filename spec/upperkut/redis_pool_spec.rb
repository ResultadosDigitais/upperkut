require 'spec_helper'

module Upperkut
  RSpec.describe RedisPool do
    describe '#create' do
      subject(:pool) { described_class.new(options).create }

      context 'when giving redis URL' do
        let(:options) do
          { url: 'redis://another.redis.url' }
        end

        it 'creates RedisPool with specific URL' do
          pool.with do |redis|
            expect(redis.connection[:host]).to eq('another.redis.url')
          end
        end
      end

      context 'whithout giving redis URL' do
        let(:options) { {} }

        it 'creates RedisPool with REDIS_URL env' do
          # avoids side-effects by stubing env instead of setting it
          allow(ENV).to receive(:[]).with('REDIS_URL').and_return('redis://my-default-redis')

          pool.with do |redis|
            expect(redis.connection[:host]).to eq('my-default-redis')
          end
        end
      end
    end
  end
end
