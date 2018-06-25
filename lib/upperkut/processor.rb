module Upperkut
  class Processor
    def initialize(manager)
      @manager = manager
      @worker  = @manager.worker
      @sleeping_time = 0
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
      @sleeping_time = 0
      @worker.new.process
    rescue Exception => ex
      # Add to retry_queue
      # if retry_limit is reached
      # send to dead
      raise ex
    end
  end
end
