require 'forwardable'
require_relative 'strategy'
require_relative 'middleware'
require_relative './util'
require_relative '../upperkut'

module Upperkut
  module Worker
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      extend Forwardable

      def_delegators :setup, :strategy, :server_middlewares, :client_middlewares
      def_delegators :strategy, :push_items, :size, :latency, :clear, :redis

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
            config.strategy = Upperkut::Strategy.new(self)
            config
          end
      end
    end
  end
end
