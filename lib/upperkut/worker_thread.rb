require_relative 'processor'

module Upperkut
  class WorkerThread
    def initialize(manager, processor)
      @manager = manager
      @processor = processor
    end

    def run
      @thread ||= Thread.new do
        begin
          @processor.blocking_process
        rescue Exception => e
          @manager.logger.debug(
            action: :processor_killed,
            reason: e,
            stacktrace: e.backtrace
          )

          @manager.notify_killed_processor(self)
        end
      end
    end

    def stop
      @processor.stop
    end

    def kill
      return unless @thread

      @thread.raise Upperkut::Shutdown
      @thread.value # wait
    end
  end
end
