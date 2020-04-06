require_relative 'logging'

module Upperkut
  class BatchExecution
    def initialize(worker, logger = Upperkut::Logging.logger)
      @worker = worker
      @logger = logger
    end

    def execute
      worker_instance = @worker.new
      items = @worker.fetch_items.freeze
      items_body = items.map(&:body)

      @worker.server_middlewares.invoke(@worker, items) do
        worker_instance.perform(items_body.dup)
      end
    rescue StandardError => error
      @logger.error(
        action: :handle_execution_error,
        ex: error.to_s,
        backtrace: error.backtrace.join("\n"),
        item_size: Array(items).size
      )

      if items
        if worker_instance.respond_to?(:handle_error)
          worker_instance.handle_error(error, items_body)
          return
        end

        @worker.push_items(items)
      end

      raise
    end
  end
end
