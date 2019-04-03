require 'upperkut/util'
require 'upperkut/redis_pool'
require 'upperkut/strategies/base'

module Upperkut
  module Strategies
    class ScheduledQueue < Upperkut::Strategies::Base
      include Upperkut::Util

      attr_reader :options

      def initialize(worker, options = {})
        @options        = options
        @redis_options  = options.fetch(:redis, {})
        @redis_pool     = setup_redis_pool
        @worker         = worker
        @max_wait   = options.fetch(
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
        items = [items] if items.is_a?(Hash)
        return false if items.empty?

        redis do |conn|
          items.each do |item|
            item = transform_item(item)
            conn.zadd(key, item[:timestamp], encode_json_item(item))
          end
        end

        true
      end

      def fetch_items
        now = Time.now.to_f.to_s
        stop = [@batch_size, size].min
        current_iteration = 0
        items = []

        redis do |conn|
          conn.multi do
            job = conn.zrangebyscore(key, '-inf'.freeze, now, :limit => [0, 1]).first
            while job.present? && current_iteration < stop do
                if conn.zrem(key, job)
                  items << job
                end
              current_iteration = current_iteration + 1
            end
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

      def fulfill_condition?(buff_size)
        return false if buff_size.zero?
        buff_size >= @batch_size || @waiting_time >= @max_wait
      end

      def size
        now = Time.now.to_f.to_s

        redis do |conn|
          conn.ZCOUNT(key, '-inf'.freeze, now)
        end
      end

      def latency
        now = Time.now.to_f.to_s

        redis do |conn|
          job = conn.zrangebyscore(key, '-inf'.freeze, now, :limit => [0, 1]).first
        end
        
        return 0 unless item
        now - item.fetch(:timestamp, Time.now).to_f
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
        "upperkut:queued:#{to_underscore(@worker.name)}"
      end

      def transform_item(item)
        attributes = item.clone
        attributes[:timestamp] = DateTime.now.strftime('%s') unless attributes.key?(:timestamp)
        attributes
      end

      def encode_json_item(item)
        JSON.generate(
          'enqueued_at' => Time.now.to_i,
          'body'        => item
        )
      end
    end
  end
end
