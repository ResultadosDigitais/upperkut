require 'forwardable'
require_relative 'strategy'
require_relative './util'
require_relative '../upperkut'

module Upperkut
  module Worker

    def self.included(base)
      base.extend(ClassMethods)
    end

    def process
      items = self.class.fetch_items
      perform(items)
    end

    module ClassMethods
      extend Forwardable

      def_delegators :setup, :strategy
      def_delegators :strategy, :push_items, :fetch_items, :size

      def push_items(items)
        strategy.push_items(items)
      end

      def fetch_items
        strategy.fetch_items(setup.batch_size)
      end

      def setup_upperkut(&block)
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
