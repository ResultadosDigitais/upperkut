require_relative 'core_ext'
require_relative 'worker_thread'
require_relative 'worker'

module Upperkut
  class Manager
    attr_accessor :worker
    attr_reader :stopped, :logger, :concurrency, :processors

    def initialize(opts = {})
      self.worker = opts.fetch(:worker).constantize
      @concurrency = opts.fetch(:concurrency, 1)
      @logger = opts.fetch(:logger, Upperkut::Logging.logger)

      @stopped = false
      @processors = []
    end

    def run
      @concurrency.times do
        processor = WorkerThread.new(self)
        @processors << processor
        processor.run
      end
    end

    def stop
      @stopped = true
    end

    def kill
      @processors.each(&:kill)
    end

    def notify_killed_processor(processor)
      @processors.delete(processor)
      return if @stopped

      processor = WorkerThread.new(self)
      @processors << processor
      processor.run
    end
  end
end
