require_relative 'logging'

module Upperkut
  class BatchExecution
    include Upperkut::Util

    def initialize(worker, logger = Upperkut::Logging.logger)
      @worker = worker
      @logger = logger
    end

    def execute
      worker_instance = @worker.new
      items = @worker.fetch_items
      items_body = items.map { |item| item.body }

      @worker.server_middlewares.invoke(@worker, items) do
        worker_instance.perform(items_body)
      end
    rescue StandardError => error
      @logger.info(
        action: :requeue,
        ex: error,
        item_size: items.size
      )

      @logger.error(error.backtrace.join("\n"))

      if worker_instance.respond_to?(:handle_error)
        worker_instance.handle_error(error, items)
        return
      end

      @worker.push_items(items)
      raise error
    end
  end
end
