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
        initialize_options
        @redis_pool = setup_redis_pool
        @worker = worker
      end

      def push_items(items = [])
        items = [items] if items.is_a?(Hash)
        return false if items.empty?

        redis do |conn|
          items.each do |item|
            ensure_timestamp_attr(item)
            conn.zadd(key, item['timestamp'], encode_json_item(item))
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

      def initialize_options
        @redis_options = @options.fetch(:redis, {})

        @batch_size = @options.fetch(
          :batch_size,
          Integer(ENV['UPPERKUT_BATCH_SIZE'] || 1000)
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
        now_timestamp = now.to_f
        job = nil

        redis do |conn|
          job = conn.zrangebyscore(key, '-inf'.freeze, now_timestamp.to_s, limit: [0, 1]).first
          job = decode_json_items([job]).first
        end

        return 0 unless job

        now_timestamp - job['body'].fetch('timestamp', now).to_f
      end

      def setup_redis_pool
        return @redis_options if @redis_options.is_a?(ConnectionPool)

        RedisPool.new(options.fetch(:redis, {})).create
      end

      def redis
        raise ArgumentError, 'requires a block' unless block_given?

        @redis_pool.with do |conn|
          yield conn
        end
      end

      def key
        "upperkut:queued:#{to_underscore(@worker.name)}"
      end

      def ensure_timestamp_attr(item)
        item['timestamp'] = Time.now.utc.to_i unless item.key?('timestamp')
      end

      def encode_json_item(item)
        JSON.generate(
          'enqueued_at' => Time.now.utc.to_i,
          'body' => item
        )
      end
    end
  end
end
