require 'time'
require 'upperkut/util'
require 'upperkut/redis_pool'
require 'upperkut/strategies/base'

module Upperkut
  module Strategies
    # Public: Encapsulates methods required to build a Scheculed Queue
    # Items are queued, but are only fetched at a specific point in time.
    class ScheduledQueue < Upperkut::Strategies::Base
      include Upperkut::Util

      ZPOPBYRANGE = %(
        local score_from = ARGV[1]
        local score_to = ARGV[2]
        local limit = ARGV[3]

        local values = redis.call('zrangebyscore', KEYS[1], score_from, score_to, 'LIMIT', '0', limit)

        if table.getn(values) > 0 then
          redis.call('zrem', KEYS[1], unpack(values))
        end

        return values
      ).freeze

      attr_reader :options

      def initialize(worker, options = {})
        @options = options
        @redis_options = @options.fetch(:redis, {})
        @worker = worker

        @batch_size = @options.fetch(
          :batch_size,
          Integer(ENV['UPPERKUT_BATCH_SIZE'] || 1000)
        )
      end

      def push_items(items = [])
        items = normalize_items(items)
        return false if items.empty?

        redis do |conn|
          items.each do |item|
            schedule_item = ensure_timestamp_attr(item)
            timestamp = schedule_item.body['timestamp']
            conn.zadd(key, timestamp, encode_json_items(schedule_item))
          end
        end

        true
      end

      def fetch_items
        args = {
          value_from: '-inf'.freeze,
          value_to: Time.now.utc.to_f.to_s,
          limit: @batch_size
        }
        items = []

        redis do |conn|
          items = pop_values(conn, args)
        end

        decode_json_items(items)
      end

      def clear
        redis { |conn| conn.del(key) }
      end

      def ack(_items); end

      def nack(items)
        push_items(items)
      end

      def metrics
        {
          'latency' => latency,
          'size' => size
        }
      end

      def process?
        buff_size = size('-inf', Time.now.utc.to_i)
        return true if fulfill_condition?(buff_size)

        false
      end

      private

      def key
        "upperkut:queued:#{to_underscore(@worker.name)}"
      end

      def ensure_timestamp_attr(item)
        return item if item.body.key?('timestamp')

        Item.new(
          id: item.id,
          body: item.body.merge('timestamp' => Time.now.utc.to_i),
          enqueued_at: item.enqueued_at
        )
      end

      def pop_values(redis_client, args)
        value_from = args[:value_from]
        value_to = args[:value_to]
        limit = args[:limit]
        redis_client.eval(ZPOPBYRANGE, keys: [key], argv: [value_from, value_to, limit])
      end

      def fulfill_condition?(buff_size)
        !buff_size.zero?
      end

      def size(min = '-inf', max = '+inf')
        redis do |conn|
          conn.zcount(key, min, max)
        end
      end

      def latency
        now = Time.now.utc
        timestamp = now.to_f

        item = redis do |conn|
          item = conn.zrangebyscore(key, '-inf', timestamp.to_s, limit: [0, 1]).first
          decode_json_items([item]).first
        end

        return timestamp - item.body['timestamp'].to_f if item

        0
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
