module Upperkut
  module Middlewares
    class Datadog
      def call(worker, _items)
        ::Datadog.tracer.trace(worker.name) do
          yield
        end
      end
    end
  end
end
