module Upperkut
  module Strategies
    class Base
      # Public: Ingests the event into strategy.
      #
      # items - The Array of items do be inserted.
      #
      # Returns true when success, raise when error.
      def push_items(items = [])
        raise NotImplementedError
      end

      # Public: Retrieve events from Strategy.
      #
      # batch_size: # of items to be retrieved.
      #
      # Returns an Array containing events as hash.
      def fetch_items(batch_size)
        raise NotImplementedError
      end

      # Public: Clear all data related to the strategy.
      def clear
        raise NotImplementedError
      end

      # Public: Tells when to execute the event processing,
      # when this condition is met so the events are dispatched to
      # the worker.
      def process?
        raise NotImplementedError
      end

      # Public: Consolidated strategy metrics.
      #
      # Returns hash containing metric name and values.
      def metrics
        raise NotImplementedError
      end
    end
  end
end
