require 'upperkut/util'
require 'upperkut/redis_pool'
require 'upperkut/strategies/base'

module Upperkut
  module Strategies
    class Queue < Upperkut::Strategies::Base
      include Upperkut::Util

      attr_reader :options

      def initialize(worker, options = {})
        @options    = options
        @redis_options = options.fetch(:redis, {})
        @redis_pool = setup_redis_pool
        @worker     = worker
      end

      def push_items(items = [])
        items = [items] if items.is_a?(Hash)
        return false if items.empty?
        redis do |conn|
          conn.rpush(key, encode_json_items(items))
        end

        true
      end

      def fetch_items(batch_size = 1000)
        stop = [batch_size, size].min

        items = redis do |conn|
          conn.multi do
            stop.times { conn.lpop(key) }
          end
        end

        decode_json_items(items)
      end

      def clear
        redis { |conn| conn.del(key) }
      end

      def metrics
        {
          'latency' => latency,
          'size'    => size
        }
      end

      private

      def size
        redis do |conn|
          conn.llen(key)
        end
      end

      def latency
        item = redis { |conn| conn.lrange(key, 0, 0) }
        item = decode_json_items(item).first
        return 0 unless item
        now = Time.now.to_f
        now - item.fetch('enqueued_at', Time.now).to_f
      end



      def setup_redis_pool
        return @redis_options if @redis_options.is_a?(ConnectionPool)
        RedisPool.new(options.fetch(:redis, {})).create
      end

      def redis
        raise ArgumentError, "requires a block" unless block_given?
        @redis_pool.with do |conn|
          yield conn
        end
      end

      def key
        "upperkut:buffers:#{to_underscore(@worker.name)}"
      end
    end
  end
end
