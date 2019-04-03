module Upperkut
  module Middleware
    class Chain
      attr_reader :items

      def initialize
        @items = []
      end

      def add(item)
        return @items if @items.include?(item)

        @items << item
      end

      def remove(item)
        @items.delete(item)
      end

      def invoke(*args)
        chain = @items.map(&:new)

        traverse_chain = lambda do
          if chain.empty?
            yield
          else
            chain.shift.call(*args, &traverse_chain)
          end
        end

        traverse_chain.call
      end
    end
  end
end
