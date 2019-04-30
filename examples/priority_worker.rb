require_relative '../lib/upperkut/worker'
require_relative '../lib/upperkut/strategies/priority_queue'

class PriorityWorker
  include Upperkut::Worker

  setup_upperkut do |config|
    config.strategy = Upperkut::Strategies::PriorityQueue.new(
      self,
      priority_key: -> { |item| item['tenant_id'] },
      batch_size: 1
    )
  end

  def perform(items)
    items.each do |item|
      puts "event dispatched: #{item.inspect}"
      sleep 1
    end
  end
end
