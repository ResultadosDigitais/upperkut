require 'forwardable'
require 'upperkut/strategies/queue'
require 'upperkut/middleware'
require 'upperkut/util'
require 'upperkut'

module Upperkut
  module Worker
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      extend Forwardable

      def_delegators :setup, :strategy, :server_middlewares, :client_middlewares
      def_delegators :strategy, :metrics, :clear

      def push_items(items)
        client_middlewares.invoke(self, items) do
          strategy.push_items(items)
        end
      end

      def fetch_items
        strategy.fetch_items(setup.batch_size)
      end

      def setup_upperkut
        yield(setup) if block_given?
      end

      def setup
        @config ||=
          begin
            config = Upperkut::Configuration.default.clone
            config.strategy = Upperkut::Strategies::Queue.new(self)
            config
          end
      end
    end
  end
end
