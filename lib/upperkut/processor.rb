module Upperkut
  class Processor

    def initialize(manager)
      @manager = manager
      @worker  = @manager.worker
      @sleeping_time = 0
    end

    def process
      loop do
        if should_process?
          @sleeping_time = 0
          process_batch
          next
        end

        puts "sleeping for #{@worker.setup.polling_interval} seconds"
        @sleeping_time += sleep(@worker.setup.polling_interval)
      end
    end

    private

    def should_process?
      return false if @manager.stopped

      # TODO: rename #setup by config
      @worker.size >= @worker.setup.batch_size ||
        @sleeping_time >= @worker.setup.max_wait
    end

    def process_batch
      begin
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
end
