require_relative 'core_ext'
require_relative 'processor'
require_relative 'worker'

module Upperkut
  class Manager
    attr_accessor :worker
    attr_reader :stopped, :logger, :concurrency, :processors

    def initialize(opts = {})
      self.worker = opts.fetch(:worker).constantize
      @concurrency = opts.fetch(:concurrency, 25)
      @logger = opts.fetch(:logger, Upperkut::Logging.logger)

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
