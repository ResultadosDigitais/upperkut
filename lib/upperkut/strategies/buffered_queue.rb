require 'upperkut/util'
require 'upperkut/redis_pool'
require 'upperkut/strategies/base'

module Upperkut
  module Strategies
    class BufferedQueue < Upperkut::Strategies::Base
      include Upperkut::Util

      DEQUEUE_ITEMS = %(
        local key = KEYS[1]
        local waiting_ack_key = KEYS[2]
        local batch_size = ARGV[1]
        local current_timestamp = ARGV[2]
        local expired_ack_timestamp = ARGV[3] + 1

        -- move expired items back to the queue
        local expired_ack_items = redis.call("ZRANGEBYSCORE", waiting_ack_key, 0, expired_ack_timestamp)
        if table.getn(expired_ack_items) > 0 then
          redis.call("ZREMRANGEBYSCORE", waiting_ack_key, 0, expired_ack_timestamp)
          for i, item in ipairs(expired_ack_items) do
            redis.call("RPUSH", key, item)
          end
        end

        -- now fetch a batch
        local items = redis.call("LRANGE", key, 0, batch_size - 1)
        for i, item in ipairs(items) do
          redis.call("ZADD", waiting_ack_key, current_timestamp + tonumber('0.' .. i), item)
        end
        redis.call("LTRIM", key, batch_size, -1)

        return items
      ).freeze

      ACK_ITEMS = %(
        local waiting_ack_key = KEYS[1]
        local items = ARGV

        for i, item in ipairs(items) do
          redis.call("ZREM", waiting_ack_key, item)
        end
      ).freeze

      NACK_ITEMS = %(
        local key = KEYS[1]
        local waiting_ack_key = KEYS[2]
        local items = ARGV

        for i, item in ipairs(items) do
          redis.call("ZREM", waiting_ack_key, item)
          redis.call("RPUSH", key, item)
        end
      ).freeze

      attr_reader :options

      def initialize(worker, options = {})
        @options = options
        @redis_options = options.fetch(:redis, {})
        @worker = worker

        @ack_wait_limit = options.fetch(
          :ack_wait_limit,
          Integer(ENV['UPPERKUT_ACK_WAIT_LIMIT'] || 120)
        )

        @max_wait = options.fetch(
          :max_wait,
          Integer(ENV['UPPERKUT_MAX_WAIT'] || 20)
        )

        @batch_size = options.fetch(
          :batch_size,
          Integer(ENV['UPPERKUT_BATCH_SIZE'] || 1000)
        )

        @waiting_time = 0
      end

      def push_items(items = [])
        items = normalize_items(items)
        return false if items.empty?

        redis do |conn|
          conn.rpush(key, items.map(&:to_json))
        end

        true
      end

      def fetch_items
        batch_size = [@batch_size, size].min

        items = redis do |conn|
          conn.eval(DEQUEUE_ITEMS,
                    keys: [key, processing_key],
                    argv: [batch_size, Time.now.utc.to_i, Time.now.utc.to_i - @ack_wait_limit])
        end

        decode_json_items(items)
      end

      def clear
        redis { |conn| conn.del(key) }
      end

      def ack(items)
        raise ArgumentError, 'Invalid item' unless items.all? { |item| item.is_a?(Item) }

        redis do |conn|
          conn.eval(ACK_ITEMS,
                    keys: [processing_key],
                    argv: items.map(&:to_json))
        end
      end

      def nack(items)
        raise ArgumentError, 'Invalid item' unless items.all? { |item| item.is_a?(Item) }

        redis do |conn|
          conn.eval(NACK_ITEMS,
                    keys: [key, processing_key],
                    argv: items.map(&:to_json))
        end
      end

      def process?
        buff_size = size

        if fulfill_condition?(buff_size)
          @waiting_time = 0
          return true
        else
          @waiting_time += @worker.setup.polling_interval
          return false
        end
      end

      def metrics
        current_latency = latency

        {
          'latency' => current_latency,
          'oldest_unacked_item_age' => oldest_item_age(current_latency),
          'size' => size
        }
      end

      private

      def key
        "upperkut:buffers:#{to_underscore(@worker.name)}"
      end

      def processing_key
        "#{key}:processing"
      end

      def fulfill_condition?(buff_size)
        return false if buff_size.zero?

        buff_size >= @batch_size || @waiting_time >= @max_wait
      end

      def oldest_item_age(current_latency)
        oldest_processing_item = redis do |conn|
          items = conn.zrange(processing_key, 0, 0)
          decode_json_items(items).first
        end

        oldest_processing_age = if oldest_processing_item
                                  now = Time.now.to_f
                                  now - oldest_processing_item.enqueued_at.to_f
                                else
                                  0
                                end

        [current_latency, oldest_processing_age].max
      end

      def latency
        items = redis { |conn| conn.lrange(key, 0, 0) }
        first_item = decode_json_items(items).first
        return 0 unless first_item

        now = Time.now.to_f
        now - first_item.enqueued_at.to_f
      end

      def size
        redis do |conn|
          conn.llen(key)
        end
      end

      def redis
        raise ArgumentError, 'requires a block' unless block_given?

        retry_block do
          redis_pool.with do |conn|
            yield conn
          end
        end
      end

      def redis_pool
        @redis_pool ||= begin
                          if @redis_options.is_a?(ConnectionPool)
                            @redis_options
                          else
                            RedisPool.new(@redis_options).create
                          end
                        end
      end
    end
  end
end
