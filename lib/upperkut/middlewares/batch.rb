require_relative '../strategies/batch_queue'

module Upperkut
  module Middlewares
    class Batch
      include Upperkut::Util

      def call(worker, items)
        if worker.strategy.class == Upperkut::Strategies::BatchQueue
          batch_id = items.first['body']['batch_id']

          begin
            yield
            success(worker, batch_id)
          rescue Exception => error
            failure(worker, batch_id, error)
          end
        else
          yield
        end
      end

      private

      def success(worker, batch_id)
        success = redis.incr("#{key(worker, batch_id)}:success")
        total = redis.get("#{key(worker, batch_id)}:total")

        if success.to_i == total.to_i && worker.strategy.callback.present?
          worker.strategy.callback.push_items([{ batch_id: batch_id }])
        end
      end

      def failure(worker, batch_id, _error)
        # TODO: Store error
        redis.incr("#{key(worker, batch_id)}:failures")
      end

      def key(worker, batch_id)
        "upperkut:batch:#{to_underscore(worker.name)}:#{batch_id}"
      end

      # TODO: Batch Redis global connection
      def redis
        @redis ||= Redis.new
      end
    end
  end
end
