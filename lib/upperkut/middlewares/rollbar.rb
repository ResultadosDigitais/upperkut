module Upperkut
  module Middlewares
    class Rollbar
      def call(worker, items)
        ::Rollbar.reset_notifier!
        yield
      rescue Exception => e
        handle_exception(e, worker, items)
        raise e
      end

      private

      def handle_exception(e, worker, items)
        scope = {
          framework: "Upperkut #{::Upperkut::VERSION}",
          request: { params: { items_size: items.size } },
          context: worker.name
        }

        ::Rollbar.scope(scope).error(e, use_exception_level_filters: true)
      end
    end
  end
end
