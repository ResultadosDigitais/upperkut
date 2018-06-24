require_relative 'core_ext'
require_relative 'processor'

module Upperkut
  class Manager

    attr_accessor :worker, :redis
    attr_reader :stopped

    def initialize(opts = {})
      self.worker = opts.fetch(:worker).constantize
      self.redis  = worker.setup.redis

      @stopped = false
    end

    def run
      Processor.new(self).process
    end

    def stop
      @stopped = true
    end
  end
end
