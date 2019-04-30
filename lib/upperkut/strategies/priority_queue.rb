module Upperkut
  module Strategies
    # Public: Queue that prevent a single tenant from taking over.
    class PriorityQueue < Upperkut::Strategies::Base
      include Upperkut::Util

      # Logic as follows:
      #
      # We keep the last score used for each tenant key. One tenant_key is
      #  an tenant unique id. To calculate the next_score we use
      #  max(current_tenant_score, current_global_score) + increment we store
      #  the queue in a sorted set using the next_score as ordering key if one
      #  tenant sends lots of messages, this tenant ends up with lots of
      #  messages in the queue spaced by increment if another tenant then
      #  sends a message, since it previous_tenant_score is lower than the
      #  first tenant, it will be inserted before it in the queue.
      #
      # In other words, the idea of this queue is to not allowing an tenant
      #  that sends a lot of messages to dominate processing and give a chance
      #  for tenants that sends few messages to have a fair share of
      #  processing time.
      ENQUEUE_ITEM = %(
        local increment = 1
        local current_checkpoint = tonumber(redis.call("GET", KEYS[1])) or 0
        local score_key = KEYS[2]
        local current_score = tonumber(redis.call("GET", score_key)) or 0
        local queue_key = KEYS[3]
        local next_score = nil

        if current_score >= current_checkpoint then
          next_score = current_score + increment
        else
          next_score = current_checkpoint + increment
        end

        redis.call("SETEX", score_key, 86400, next_score)
        redis.call("ZADD", queue_key, next_score, ARGV[1])

        return next_score
      ).freeze

      # Uses ZPOP* functions available only on redis 5.0.0+
      DEQUEUE_ITEM = %(
        local checkpoint_key = KEYS[1]
        local queue_key = KEYS[2]
        local batch_size = ARGV[1]
        local popped_items = redis.call("ZPOPMIN", queue_key, batch_size)
        local items = {}
        local last_score = 0

        for i, v in ipairs(popped_items) do
          if i % 2 == 1 then
            table.insert(items, v)
          else
            last_score = v
          end
        end

        redis.call("SETEX", checkpoint_key, 86400, last_score)
        return items
      ).freeze

      def initialize(worker, options)
        @worker = worker
        @options = options
        @priority_key = options.fetch(:priority_key)
        @redis_options = options.fetch(:redis, {})

        @max_wait = options.fetch(
          :max_wait,
          Integer(ENV['UPPERKUT_MAX_WAIT'] || 20)
        )

        @batch_size = options.fetch(
          :batch_size,
          Integer(ENV['UPPERKUT_BATCH_SIZE'] || 1000)
        )

        @waiting_time = 0

        raise ArgumentError, 'Invalid priority_key. ' \
          'Must be a lambda' unless @priority_key.respond_to?(:call)
      end

      # Public: Ingests the event into strategy.
      #
      # items - The Array of items do be inserted.
      #
      # Returns true when success, raise when error.
      def push_items(items = [])
        items = [items] if items.is_a?(Hash)
        return false if items.empty?

        redis do |conn|
          items.each do |item|
            priority_key = @priority_key.call(item)
            score_key = "#{queue_key}:#{priority_key}:score"

            keys = [queue_checkpoint_key,
                    score_key,
                    queue_key]

            conn.eval(ENQUEUE_ITEM,
                      keys: keys,
                      argv: [encode_json_items([item])])
          end
        end

        true
      end

      # Public: Retrieve events from Strategy.
      #
      # Returns an Array containing events as hash.
      def fetch_items
        batch_size = [@batch_size, size].min

        items = redis do |conn|
          conn.eval(DEQUEUE_ITEM,
                    keys: [queue_checkpoint_key, queue_key],
                    argv: [batch_size])
        end

        decode_json_items(items)
      end

      # Public: Clear all data related to the strategy.
      def clear
        redis { |conn| conn.del(queue_key) }
      end

      # Public: Tells when to execute the event processing,
      # when this condition is met so the events are dispatched to
      # the worker.
      def process?
        if fulfill_condition?(size)
          @waiting_time = 0
          return true
        end

        @waiting_time += @worker.setup.polling_interval
        false
      end

      # Public: Consolidated strategy metrics.
      #
      # Returns hash containing metric name and values.
      def metrics
        {
          'size' => size
        }
      end

      private

      def queue_checkpoint_key
        "#{queue_key}:checkpoint"
      end

      def queue_key
        "upperkut:priority_queue:#{to_underscore(@worker.name)}"
      end

      def fulfill_condition?(buff_size)
        return false if buff_size.zero?

        buff_size >= @batch_size || @waiting_time >= @max_wait
      end

      def size
        redis do |conn|
          conn.zcard(queue_key)
        end
      end

      def redis
        raise ArgumentError, 'requires a block' unless block_given?

        redis_pool.with do |conn|
          yield conn
        end
      end

      def redis_pool
        @redis_pool ||= begin
                          if @redis_options.is_a?(ConnectionPool)
                            @redis_options
                          else
                            RedisPool.new(@options.fetch(:redis, {})).create
                          end
                        end
      end
    end
  end
end
