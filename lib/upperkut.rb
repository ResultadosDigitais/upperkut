require_relative "upperkut/version"
require_relative 'upperkut/worker'
require 'redis'

module Upperkut
  class Configuration
    attr_accessor :batch_size, :redis, :strategy, :max_wait, :polling_interval

    def self.default
      new.tap do |config|
        config.batch_size       = 1_000
        config.redis            = Redis.new
        config.max_wait         = Integer(ENV['UPPERKUT_MAX_WAIT'] || 20)
        config.polling_interval = Integer(ENV['UPPERKUT_POLLING_INTERVAL'] || 5)
      end
    end
  end
end
