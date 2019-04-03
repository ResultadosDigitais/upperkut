require 'spec_helper'

module Upperkut
  RSpec.describe RedisPool do
    describe '.initialize' do
      context 'when giving redis URL' do
        let(:options) { { redis: { url: 'another.redis.url' } } }

        it 'creates RedisPool with specific URL' do
          expect(RedisPool.new(options.fetch(:redis, {})).instance_variable_get(:@options)[:url])
            .to eq(options[:redis][:url])
        end
      end

      context 'whithout giving redis URL' do
        let(:options) { { redis: {} } }

        it 'creates RedisPool with REDIS_URL env' do
          expect(RedisPool.new(options.fetch(:redis, {})).instance_variable_get(:@options)[:url])
            .to eq(ENV['REDIS_URL'])
        end
      end
    end
  end
end
