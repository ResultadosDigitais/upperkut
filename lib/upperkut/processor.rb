require_relative 'logging'

module Upperkut
  class Processor
    def initialize(worker, logger = Logging.logger)
      @worker = worker
      @strategy = worker.strategy
      @worker_instance = worker.new
      @logger = logger
    end

    def process
      items = @worker.fetch_items.freeze
      items_body = items.map(&:body)

      @worker.server_middlewares.invoke(@worker, items) do
        @worker_instance.perform(items_body.dup)
      end

      @strategy.ack(items)
    rescue StandardError => error
      @logger.error(
        action: :handle_execution_error,
        ex: error.to_s,
        backtrace: error.backtrace.join("\n"),
        item_size: Array(items).size
      )

      if items
        if @worker_instance.respond_to?(:handle_error)
          @worker_instance.handle_error(error, items_body)
          return
        end

        @strategy.nack(items)
      end

      raise error
    end

    def blocking_process
      sleeping_time = 0

      loop do
        break if @stopped

        if @strategy.process?
          sleeping_time = 0
          process
          next
        end

        sleeping_time += sleep(@worker.setup.polling_interval)
        @logger.debug(sleeping_time: sleeping_time)
      end
    end

    def stop
      @stopped = true
    end
  end
end
