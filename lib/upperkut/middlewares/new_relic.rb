module Upperkut
  module Middlewares
    class NewRelic
      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation

      def call(worker, _items)
        perform_action_with_newrelic_trace(trace_args(worker)) do
          yield
        end
      end

      private

      def trace_args(worker)
        {
          name: 'perform',
          class_name: worker.name,
          category: 'OtherTransaction/Upperkut'
        }
      end
    end
  end
end
