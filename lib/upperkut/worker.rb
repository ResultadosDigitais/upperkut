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

      def_delegators :setup, :strategy, :middlewares
      def_delegators :strategy, :push_items, :size, :latency, :clear

      def push_items(items)
        strategy.push_items(items)
      end

      def fetch_items
        strategy.fetch_items(setup.batch_size)
      end

      def setup_upperkut
        yield(setup) if block_given?
      end

      def setup
        @@setup ||=
          begin
            default = Upperkut::Configuration.default.clone
            default.strategy ||= Upperkut::Strategy.new(self, default.redis)
            default
          end
      end
    end
  end
end
