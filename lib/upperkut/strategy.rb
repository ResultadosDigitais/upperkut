require_relative 'util'

module Upperkut
  class Strategy
    include Upperkut::Util

    attr_accessor :worker, :redis

    def initialize(worker, redis)
      self.worker = worker
      self.redis  = redis
    end

    def push_items(items = [])
      return false if items.empty?
      redis.lpush(key, encode_json_items(items))
    end

    def fetch_items(batch_size = 1000)
      stop = [batch_size, size].min

      items = redis.multi do
        stop.times do
          redis.lpop(key)
        end
      end

      decode_json_items(items)
    end

    def size
      redis.llen(key)
    end

    private

    def key
      "upperkut:buffers:#{to_underscore(worker.name)}"
    end
  end
end
