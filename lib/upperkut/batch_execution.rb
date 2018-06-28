require_relative 'logging'

module Upperkut
  class BatchExecution
    def initialize(worker, logger = Upperkut::Logging.logger)
      @worker = worker
      @logger = logger
    end

    def execute
      worker_instance = @worker.new
      items  = @worker.fetch_items.collect! do |item|
        item['body']
      end

      worker_instance.perform(items.dup)
    rescue Exception => ex
      @logger.info(
        action: :requeue,
        ex: ex,
        item_size: items.size
      )

      @worker.push_items(items)
      raise ex
    end
  end
end
