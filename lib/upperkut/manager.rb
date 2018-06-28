require_relative 'core_ext'
require_relative 'processor'

module Upperkut
  class Manager
    attr_accessor :worker, :redis
    attr_reader :stopped

    def initialize(opts = {})
      self.worker = opts.fetch(:worker).constantize
      self.redis  = worker.setup.redis
      @concurrency = opts.fetch(:concurrency, 25)
      @stopped = false
      @processors = []
    end

    def run
      @concurrency.times do
        processor = Processor.new(self)
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

      processor = Processor.new(self)
      @processors << processor
      processor.run
    end
  end
end
