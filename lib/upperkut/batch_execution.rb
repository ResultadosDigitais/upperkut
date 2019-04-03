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
      items = @worker.fetch_items.freeze

      items_body = items.collect do |item|
        item['body']
      end

      @worker.server_middlewares.invoke(@worker, items) do
        worker_instance.perform(items_body.dup)
      end
    rescue Exception => ex
      @worker.push_items(items_body)

      @logger.info(
        action: :requeue,
        ex: ex,
        item_size: items_body.size
      )

      @logger.error(ex.backtrace.join("\n"))
      raise ex
    end
  end
end
