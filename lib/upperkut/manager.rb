require_relative 'core_ext'
require_relative 'worker_thread'
require_relative 'logging'
require_relative 'worker'

module Upperkut
  class Manager
    attr_accessor :worker
    attr_reader :stopped, :logger, :concurrency

    def initialize(opts = {})
      self.worker = opts.fetch(:worker).constantize
      @concurrency = opts.fetch(:concurrency, 1)
      @logger = opts.fetch(:logger, Logging.logger)

      @stopped = false
      @threads = []
    end

    def run
      @concurrency.times do
        spawn_thread
      end
    end

    def stop
      @stopped = true
      @threads.each(&:stop)
    end

    def kill
      @threads.each(&:kill)
    end

    def notify_killed_processor(thread)
      @threads.delete(thread)
      spawn_thread unless @stopped
    end

    private

    def spawn_thread
      processor = Processor.new(worker, logger)

      thread = WorkerThread.new(self, processor)
      @threads << thread
      thread.run
    end
  end
end
