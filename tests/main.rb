require 'redis'

class MainTest
  include Upperkut::Worker

  REDIS = Redis.new

  def perform(events)
    REDIS.multi do
      events.each do |event|
        REDIS.sadd('testA', event)
      end
    end
  end
end
