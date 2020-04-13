require 'upperkut/util'
require 'upperkut/redis_pool'
require 'upperkut/strategies/base'

module Upperkut
  module Strategies
    class BufferedQueue < Upperkut::Strategies::Base
      include Upperkut::Util

      attr_reader :options

      def initialize(worker, options = {})
        @options = options
        @redis_options = options.fetch(:redis, {})
        @worker     = worker
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
        items = normalize_items(items)
        return false if items.empty?

        redis do |conn|
          conn.rpush(key, items.map(&:to_json))
        end

        true
      end

      def fetch_items
        stop = [@batch_size, size].min

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

      def ack(_items); end

      def nack(items)
        push_items(items)
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
        {
          'latency' => latency,
          'size' => size
        }
      end

      private

      def key
        "upperkut:buffers:#{to_underscore(@worker.name)}"
      end

      def fulfill_condition?(buff_size)
        return false if buff_size.zero?

        buff_size >= @batch_size || @waiting_time >= @max_wait
      end

      def size
        redis do |conn|
          conn.llen(key)
        end
      end

      def latency
        items = redis { |conn| conn.lrange(key, 0, 0) }
        first_item = decode_json_items(items).first
        return 0 unless first_item

        now = Time.now.to_f
        now - first_item.enqueued_at.to_f
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
