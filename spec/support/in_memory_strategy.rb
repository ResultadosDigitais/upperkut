require 'upperkut/util'

class InMemoryStrategy
  include Upperkut::Util

  attr_reader :items, :processing

  def initialize
    @items = []
    @processing = []
  end

  def push_items(items)
    @items.concat(normalize_items(items))
  end

  def fetch_items
    @items.slice!(0..10)
  end

  def ack(items)
  end

  def nack(items)
  end

  def clear
    @items.clear
  end

  def process?
    true
  end

  def metrics
    {
      'size' => @items.size,
      'latency' => Time.now.to_i - @items.first.enqueued_at
    }
  end
end

