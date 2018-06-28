require_relative 'batch_execution'

module Upperkut
  class Processor
    def initialize(manager)
      @manager = manager
      @worker  = @manager.worker
      @logger =  @manager.logger

      @sleeping_time = 0
    end

    def run
      @thread ||= Thread.new do
        begin
          process
        rescue Exception => e
          @logger.debug(
            action: :processor_killed,
            reason: e
          )

          @manager.notify_killed_processor(self)
        end
      end
    end

    def kill
      return unless @thread
      @thread.raise Upperkut::Shutdown
      @thread.value # wait
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
