require_relative 'batch_execution'

module Upperkut
  class Processor
    def initialize(manager)
      @manager = manager
      @worker  = @manager.worker
      @sleeping_time = 0
      @logger  = Upperkut::Logging.logger
    end

    def run
      @thread ||= Thread.new do
        process
      end
    end

    def kill
      return unless @thread
      @thread.raise Upperkut::Shutdown
    end

    private

    def process
      loop do
        if should_process?
          @sleeping_time = 0
          process_batch
          next
        end

        @sleeping_time += sleep(@worker.setup.polling_interval)
        @logger.debug(sleeping_time: @sleeping_time)
      end
    end

    def should_process?
      buffer_size = @worker.size

      return false if @manager.stopped
      return false if buffer_size.zero?

      # TODO: rename #setup by config
      buffer_size >= @worker.setup.batch_size ||
        @sleeping_time >= @worker.setup.max_wait
    end

    def process_batch
      BatchExecution.new(@worker, @logger).execute
    end
  end
end
