require_relative 'processor'

module Upperkut
  class WorkerThread
    def initialize(manager)
      @manager  = manager
      @worker   = @manager.worker
      @logger   = @manager.logger
      @strategy = @worker.strategy

      @sleeping_time = 0
    end

    def run
      @thread ||= Thread.new do
        begin
          process
        rescue Exception => e
          @logger.debug(
            action: :processor_killed,
            reason: e,
            stacktrace: e.backtrace
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
        next if @manager.stopped

        if @strategy.process?
          @sleeping_time = 0
          process_batch
          next
        end

        @sleeping_time += sleep(@worker.setup.polling_interval)
        @logger.debug(sleeping_time: @sleeping_time)
      end
    end

    def process_batch
      Processor.new(@worker, @logger).execute
    end
  end
end
