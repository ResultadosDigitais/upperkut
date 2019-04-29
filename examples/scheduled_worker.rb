require_relative '../lib/upperkut/worker'
require_relative '../lib/upperkut/strategies/scheduled_queue'

class ScheduledWorker
  include Upperkut::Worker

  setup_upperkut do |config|
    config.strategy = Upperkut::Strategies::ScheduledQueue.new(
      self,
      batch_size: 200
    )
  end

  def perform(items)
    items.each do |item|
      puts "event dispatched: #{item.inspect}"
    end
  end
end
