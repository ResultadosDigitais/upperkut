require 'securerandom'

require 'upperkut/util'
require 'upperkut/redis_pool'
require 'upperkut/strategies/base'

module Upperkut
  module Strategies
    class BatchQueue < Upperkut::Strategies::Base
      include Upperkut::Util

      attr_reader :callback

      def initialize(worker, redis_url: nil, callback: nil)
        @worker = worker
        @redis_url = redis_url
        @callback = callback

        @items = []
      end

      def commit
        return false if @items.empty?

        redis.multi do |multi|
          multi.rpush(key, encode_json_items(@items))
          multi.set("#{key}:#{batch_id}:total", @items.size)

          @items = []
        end

        batch_id
      end

      def push_items(items = [])
        return false if items.empty?

        items.each { |item| item.merge!(batch_id: batch_id) }

        @items.concat(items)
      end

      def fetch_items
        item = redis.lpop(key)

        return if item.nil?

        decode_json_items([item])
      end

      def clear
        redis.del(key)
      end

      def metrics(batch_id)
        {
          'latency'  => 0,
          'size'     => size,
          # TODO: Sorry, XGH
          'total'    => total(batch_id),
          'success'  => success(batch_id),
          'failures' => failures(batch_id),
        }
      end

      def process?
        true
      end

      private

      def batch_id
        @batch_id ||= SecureRandom.hex
      end

      def size
        redis.llen(key)
      end

      def total(batch_id)
        redis.get("#{key}:#{batch_id}:total")
      end

      def success(batch_id)
        redis.get("#{key}:#{batch_id}:success")
      end

      def failures(batch_id)
        redis.get("#{key}:#{batch_id}:failures")
      end

      # TODO: Latency logic
      def latency
        0
      end

      def key
        "upperkut:batch:#{to_underscore(@worker.name)}"
      end

      # TODO: Batch Redis global connection
      def redis
        @redis ||= Redis.new
      end
    end
  end
end
