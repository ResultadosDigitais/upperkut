require 'upperkut/util'
require 'upperkut/redis_pool'
require 'upperkut/strategies/base'

module Upperkut
  module Strategies
    # Queue where items are fetched on a specific point in time
    class ScheduledQueue < Upperkut::Strategies::Base
      include Upperkut::Util

      ZPOPBYRANGE = %(
        local score_from = ARGV[1]
        local score_to = ARGV[2]
        local limit = ARGV[3]

        local values = redis.call('zrangebyscore', KEYS[1], score_from, score_to, 'LIMIT' , '0' , limit)

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
        @waiting_time = 0
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
          value_to: Time.now.to_f.to_s,
          limit: [@batch_size, size].min
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
        buff_size = size

        if fulfill_condition?(buff_size)
          @waiting_time = 0
          return true
        else
          @waiting_time += @worker.setup.polling_interval
          return false
        end
      end

      private

      def initialize_options
        @redis_options = @options.fetch(:redis, {})

        @max_wait = @options.fetch(
          :max_wait,
          Integer(ENV['UPPERKUT_MAX_WAIT'] || 20)
        )

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
        return false if buff_size.zero?

        buff_size >= @batch_size || @waiting_time >= @max_wait
      end

      def size(min = '-inf', max = '+inf')
        redis do |conn|
          conn.zcount(key, min, max)
        end
      end

      def latency
        now = Time.now
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
        item['timestamp'] = Time.now.to_i unless item.key?('timestamp')
      end

      def encode_json_item(item)
        JSON.generate(
          'enqueued_at' => Time.now.to_i,
          'body' => item
        )
      end
    end
  end
end
