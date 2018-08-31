require_relative 'util'
require 'upperkut/redis_pool'

module Upperkut
  class Strategy
    include Upperkut::Util

    attr_accessor :worker, :redis

    def initialize(worker, options = {})
      self.worker = worker
      @redis_pool  = RedisPool.new(options[:redis] || {}).create
    end

    def redis
      raise ArgumentError, "requires a block" unless block_given?
      @redis_pool.with do |conn|
        yield conn
      end
    end

    def push_items(items = [])
      items = [items] if items.is_a?(Hash)
      return false if items.empty?
      redis do |conn|
        conn.rpush(key, encode_json_items(items))
      end
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

    def clear
      redis { |conn| conn.del(key) }
    end

    private

    def key
      "upperkut:buffers:#{to_underscore(worker.name)}"
    end
  end
end
