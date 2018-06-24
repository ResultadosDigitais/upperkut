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
        @processors << Processor.new(self).run
      end
    end

    def stop
      @stopped = true
    end

    def kill
      @processors.each do |processor|
        processor.kill
      end
    end
  end
end
