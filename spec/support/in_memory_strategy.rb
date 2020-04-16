require 'upperkut/util'

class InMemoryStrategy
  include Upperkut::Util

  attr_reader :items, :acked, :nacked

  def initialize
    @items = []
    @acked = []
    @nacked = []
  end

  def push_items(items)
    @items.concat(normalize_items(items))
  end

  def fetch_items
    @items.slice!(0..10)
  end

  def ack(items)
    @acked.concat(items)
  end

  def nack(items)
    @nacked.concat(items)
    @items.concat(items)
  end

  def clear
    @items.clear
    @acked.clear
    @nacked.clear
  end

  def process?
    true
  end

  def metrics
    latency = if @items.size.zero?
                0
              else
                Time.now.to_i - @items.first.enqueued_at
              end

    {
      'size' => @items.size,
      'latency' => latency
    }
  end
end

